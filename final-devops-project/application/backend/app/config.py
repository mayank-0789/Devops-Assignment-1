from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    app_name: str = "Stockroom"
    app_env: str = "development"
    database_url: str = "postgresql+psycopg://stockroom:stockroom@localhost:5432/stockroom"
    cors_origins: str = "http://localhost:3000,http://localhost:5173"


settings = Settings()
