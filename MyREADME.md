# Odoo Docker

Setup Odoo Docker Development Environment
https://medium.com/@reedrehg/easier-odoo-development-278bbaab38c8

GitHub Repositories inside docker-compose
https://odoo-community.org/blog/the-oca-blog-1/post/how-to-install-oca-modules-79

READ! openworx odoo docker setup -- https://www.openworx.nl/blog/blog-1/post/odoo-docker-6
READ! -- https://github.com/it-projects-llc/install-odoo/blob/12.0/Dockerfile

Important steps!
- entrypoint.sh | bin/boot must be chmod +x before Docker build

Docker images good-to-know:
- Remove none-tag Docker images: docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
- Clean up Docker volumes: docker volume rm $(docker volume ls -qf dangling=true)
- build Docker: docker build . wjriedstra/odoo:12.0-dev
- tag Docker image: docker tag imagebuildinginprocess wjriedstra/odoo:12.0
- push Docker image: docker push wjriedstra/odoo:12.0

### Todo
- [ ] docker-compose-local: extra environment variables on the fly