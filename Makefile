# This file is licensed under the Affero General Public License version 3 or
# later. See the COPYING file.
app_name=$(notdir $(CURDIR))
project_dir=$(CURDIR)/../$(app_name)
build_tools_directory=$(CURDIR)/build/tools
build_dir=$(CURDIR)/build/artifacts
composer=$(shell which composer 2> /dev/null)

all: dev-setup lint build-js-production assemble

# Dev env management
dev-setup: clean clean-dev composer npm-init


# Installs and updates the composer dependencies. If composer is not installed
# a copy is fetched from the web
composer:
ifeq (, $(composer))
	@echo "No composer command available, downloading a copy from the web"
	mkdir -p $(build_tools_directory)
	curl -sS https://getcomposer.org/installer | php
	mv composer.phar $(build_tools_directory)
	php $(build_tools_directory)/composer.phar install --prefer-dist
	php $(build_tools_directory)/composer.phar update --prefer-dist
else
	composer install --prefer-dist
	composer update --prefer-dist
endif

npm-init:
	npm ci

npm-update:
	npm update

# Building
build-js:
	npm run dev

build-js-production:
	npm run build

watch-js:
	npm run watch

serve-js:
	npm run serve

# Linting
lint:
	npm run lint

lint-fix:
	npm run lint:fix

# Style linting
stylelint:
	npm run stylelint

stylelint-fix:
	npm run stylelint:fix


# Tests
test:
	./vendor/phpunit/phpunit/phpunit -c phpunit.xml
	./vendor/phpunit/phpunit/phpunit -c phpunit.integration.xml

##### Building #####

build: clean build-js-production assemble

appstore: build
	@echo "Signing…"
#	php ../server/occ integrity:sign-app \
#		--privateKey=$(cert_dir)/$(app_name).key\
#		--certificate=$(cert_dir)/$(app_name).crt\
#		--path=$(build_dir)/$(app_name)
	tar -czf $(build_dir)/$(app_name).tar.gz \
		-C $(build_dir) $(app_name)
	# openssl dgst -sha512 -sign $(cert_dir)/$(app_name).key $(build_dir)/$(app_name).tar.gz | openssl base64

assemble:
	mkdir -p $(build_dir)
	rsync -a \
	--exclude=babel.config.js \
	--exclude=build \
	--exclude=composer.* \
	--exclude=CONTRIBUTING.md \
	--exclude=.editorconfig \
	--exclude=.eslintrc.js \
	--exclude=.git \
	--exclude=.github \
	--exclude=.gitignore \
	--exclude=.gitattributes \
	--exclude=l10n/no-php \
	--exclude=l10n/.gitkeep \
	--exclude=Makefile \
	--exclude=node_modules \
	--exclude=package*.json \
	--exclude=.php_cs.* \
	--exclude=phpunit*xml \
	--exclude=.scrutinizer.yml \
	--exclude=src \
	--exclude=.stylelintrc.js \
	--exclude=tests \
	--exclude=.travis.yml \
	--exclude=.tx \
	--exclude=.idea \
	--exclude=.vscode \
	--exclude=vendor \
	--exclude=webpack*.js \
	$(project_dir) $(build_dir)

##### Cleaning #####

clean:
	rm -rf js/
	rm -rf $(build_dir)

clean-dev:
	rm -rf node_modules
	rm -rf vendor