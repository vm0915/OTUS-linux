# Docker
Собранный образ nginx доступен размещен на dockerhub: vm0915/otus:nginx

Для запуска:
```bash
docker run -d -p 80:80 vm0915/otus:nginx
```
`curl localhost:80` выдает `Hello, Otus!`.
