require 'onesky'
require 'json'
require 'colorize'
require 'yaml'
require 'ostruct'

@config = OpenStruct.new(YAML.load_file('onesky_config.yml'))


def sync_project(project_id,locale,project_path)
	client = Onesky::Client.new(@config.api_key, @config.api_secret)
	project = client.project(project_id)
	response = project.list_file
	response = JSON.parse(response)
	files = response['data'].map{|d| d["file_name"]}
	puts "Files in #{project_id}"
	files.each {|f| puts "#{f}".yellow }
	files.each {|filename| get_file(project,filename,project_path,locale) }
end

def get_file(project,filename,strings_location,locale)
	files =  Dir.glob("#{strings_location}/**/#{filename}")
	target = files.select {| p | p.include? "#{locale}.lproj"}.first if files
	response = project.export_translation(source_file_name: filename, locale: locale) if target
	File.open(target, 'w') { |file| file.write(response)} if target
	puts "Sync #{filename}@#{project.project_id}".green if target
	puts "Do not exist #{filename}@#{project.project_id} in local".red if !target

end
@config.projects.each do |project_id,path| 
	@config.locales.each do |locale| 
	puts "sync #{locale} @ #{project_id} @ #{path}".red
	sync_project(project_id,locale,path)
end
end