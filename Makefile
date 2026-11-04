.PHONY: up up-mysql up-pg down clean ps logs exec-python exec-mysql exec-pg all-clean disintegrate

up:
	docker compose --profile mysql --profile postgres up -d --build --remove-orphans

up-mysql:
	@containers=$$(docker compose --profile postgres ps -q postgres) || exit $$?; \
	if [ -n "$$containers" ]; then docker compose --profile postgres stop postgres; fi
	docker compose --profile mysql up -d --build

up-pg:
	@containers=$$(docker compose --profile mysql ps -q mysql) || exit $$?; \
	if [ -n "$$containers" ]; then docker compose --profile mysql stop mysql; fi
	docker compose --profile postgres up -d --build

down:
	docker compose --profile mysql --profile postgres down

clean:
	docker compose --profile mysql --profile postgres down --rmi local --volumes

ps:
	docker compose --profile mysql --profile postgres ps

logs:
	docker compose --profile mysql --profile postgres logs -f

exec-python:
	docker compose exec python bash

exec-mysql:
	docker compose exec mysql bash

exec-pg:
	docker compose exec postgres bash

all-clean:
	docker system prune -f

disintegrate:
	docker system prune -a --volumes -f
