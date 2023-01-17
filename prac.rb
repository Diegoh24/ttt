require 'yaml'
path = './data/players.yml'
s = YAML.load_file('./data/players.yml')


# File.open(path, 'w') do |file|
#   file.write(Psych.dump_stream(s))
# end
p s