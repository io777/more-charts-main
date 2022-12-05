FROM python:alpine

# This prevents Python from writing out pyc files
ENV PYTHONDONTWRITEBYTECODE 1

# This keeps Python from buffering stdin/stdout
ENV PYTHONUNBUFFERED 1

# Setup
RUN apk update
RUN apk upgrade
RUN apk add --update\
    bash            \
    postgresql-dev  \
    gcc             \
    python3-dev     \
    musl-dev        \
    jpeg-dev        \
    zlib-dev        \
    libffi-dev

RUN pip install --upgrade pip

WORKDIR /app

COPY ./requirements.txt ./

RUN python3 -m pip install -r requirements.txt --cache-dir=/app/api/pip_cache/

# Clean
RUN apk del -r python3-dev postgresql

CMD ["python3", "manage.py", "runserver", "0.0.0.0:8000"]

EXPOSE 8000

