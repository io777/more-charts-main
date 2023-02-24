#!/bin/sh

SQL_DATABASE_VAR=`cat /run/secrets/sql_database`
SQL_HOST_VAR=`cat /run/secrets/sql_host`
SQL_PORT_VAR=`cat /run/secrets/sql_port`
ACTION="run"

BASE_PATH=`dirname $0`
TRY_LOOP="20"

# Ожедание запуска базы данных.
wait_for_port() {
    local name="$1" host="$2" port="$3"
    local j=0
    while ! nc -z "$host" "$port" >/dev/null 2>&1 < /dev/null; do
        j=$((j+1))
        if [ $j -ge $TRY_LOOP ]; then
            echo >&2 "$(date) - $host:$port still not reachable, giving up"
            exit 1
        fi
        echo "$(date) - waiting for $name... $j/$TRY_LOOP"
        sleep 5
    done
}

# Запуск сервера
run(){
    gunicorn api.wsgi:application -w 4 -b 0.0.0.0:8000
}

# Создание новых миграций на основе изменений.
migrations(){
    python manage.py makemigrations
}

# Применение миграций.
migrate(){
    python manage.py migrate $1
}

# Выполним подготовку/сборку статических файлов.
collectstatic(){
    python manage.py collectstatic --no-input
}

case $ACTION in
    run)
        wait_for_port "$SQL_DATABASE_VAR" "$SQL_HOST_VAR" "$SQL_PORT_VAR"
        echo ""
        echo "==================================================="
        echo "=          Migrations model.                      ="
        echo "==================================================="
        migrations

        echo ""
        echo "==================================================="
        echo "=          Migrate models.                        ="
        echo "==================================================="
        migrate "auth"
        migrate "--run-syncdb --no-input"

        echo ""
        echo "==================================================="
        echo "=         Let's prepare/build static files.       ="
        echo "==================================================="
        collectstatic

        echo ""
        echo "==================================================="
        echo "=             Run server.                    ="
        echo "==================================================="
        run $2
    ;;
    migrations)
        echo ""
        echo "==================================================="
        echo "=          Migrations models.                     ="
        echo "==================================================="
        migrations
    ;;
    migrate)
        echo ""
        echo "==================================================="
        echo "=          Migrate models.                        ="
        echo "==================================================="
        migrate
    ;;
    collectstatic)
        echo ""
        echo "==================================================="
        echo "=         Let's prepare/build static files.       ="
        echo "==================================================="
        collectstatic
    ;;
    *) echo "Invalid option: $1"
    ;;
esac

exit 0