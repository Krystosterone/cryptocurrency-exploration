source "https://rubygems.org"
ruby "2.5.0"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "activesupport"
gem "byebug"
gem "concurrent-ruby"
gem "httparty"
gem "sinatra"

group :test do
  gem "rack-test"
  gem "rspec"
end
