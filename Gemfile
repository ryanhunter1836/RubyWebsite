source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem 'rails',                      '6.0.2.2'
gem 'active_storage_validations', '0.8.2'
gem 'bcrypt',                     '3.1.13'
gem 'will_paginate',              '3.1.8'
gem 'bootstrap',                  '4.3.1'
gem 'pg',                         '1.2.3'
gem 'popper_js',                  '1.16.0'
gem 'sprockets-rails',            '2.3.3'
gem 'puma',                       '4.3.5'
gem 'sass-rails',                 '6.0.0'
gem 'webpacker',                  '4.2.2'
gem 'turbolinks',                 '5.2.1'
gem 'jbuilder',                   '2.10.0'
gem 'bootsnap',                   '1.4.6', require: false
gem 'font-awesome-sass',          '~> 5.13.0'
gem 'stripe',                     '5.23.1'
gem 'capistrano',                 '~> 3.11'
gem 'capistrano-rails',           '~> 1.4'
gem 'capistrano-passenger',       '~> 0.2.0'
gem 'capistrano-rbenv',           '~> 2.1', '>= 2.1.4'
gem 'listen',                     '3.1.5'

group :development do
  gem 'web-console',           '4.0.1'
  gem 'spring',                '2.1.0'
  gem 'spring-watcher-listen', '2.0.1'
  gem 'ruby-debug-ide',        '0.7.0'
  gem 'debase',                '0.2.4.1'
  gem 'solargraph',            '0.39.15'
end

group :test do
  gem 'capybara',                 '3.28.0'
  gem 'selenium-webdriver',       '3.142.3'
  gem 'webdrivers',               '4.1.2'
  gem 'rails-controller-testing', '1.0.4'
  gem 'minitest',                 '5.11.3'
  gem 'minitest-reporters',       '1.3.8'
  gem 'guard',                    '2.16.2'
  gem 'guard-minitest',           '2.4.6'
end

group :development, :test do
  gem 'byebug',  '11.0.1', platforms: [:mri, :mingw, :x64_mingw]
end

group :production do
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
