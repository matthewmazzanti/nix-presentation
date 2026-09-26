import os
import secrets
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.responses import RedirectResponse
from psycopg_pool import AsyncConnectionPool
from pydantic import BaseModel, HttpUrl
from redis.asyncio import Redis

db = AsyncConnectionPool(os.environ["DATABASE_URL"], open=False)
cache = Redis.from_url(os.environ["REDIS_URL"], decode_responses=True)


@asynccontextmanager
async def lifespan(_: FastAPI):
    await db.open()
    async with db.connection() as conn:
        await conn.execute(
            "CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT NOT NULL)"
        )
    yield
    await db.close()
    await cache.aclose()


app = FastAPI(lifespan=lifespan)


class Link(BaseModel):
    url: HttpUrl


@app.post("/links")
async def shorten(link: Link):
    code = secrets.token_urlsafe(4)
    async with db.connection() as conn:
        await conn.execute("INSERT INTO links VALUES (%s, %s)", (code, str(link.url)))
    return {"code": code}


@app.get("/{code}")
async def follow(code: str):
    url = await cache.get(f"link:{code}")
    if url is None:
        async with db.connection() as conn:
            cur = await conn.execute("SELECT url FROM links WHERE code = %s", (code,))
            row = await cur.fetchone()
        if row is None:
            raise HTTPException(404)
        url = row[0]
        await cache.set(f"link:{code}", url, ex=3600)
    await cache.incr(f"hits:{code}")
    return RedirectResponse(url)


@app.get("/{code}/stats")
async def stats(code: str):
    return {"hits": int(await cache.get(f"hits:{code}") or 0)}


def main():
    uvicorn.run(
        app, host=os.getenv("HOST", "127.0.0.1"), port=int(os.getenv("PORT", "8000"))
    )
