#!/usr/bin/env ruby
require 'optparse'
require 'rubygems'
require 'iconv' unless String.method_defined?(:encode) #because http://stackoverflow.com/questions/2982677/ruby-1-9-invalid-byte-sequence-in-utf-8

$OPT = { #Options
	:online=>false,
}

OptionParser.new do|opts|
	opts.banner = "Usage: kupu [options]. Publish kumamoto-source into kumamoto-public."
	opts.on( '-o', '--online', 'Publish with online paths. Default false.' ) do
		$OPT[:online] = true
	end
end.parse!

pwd = Dir.pwd+'/'
publicDir =  pwd.gsub(/kumamoto-source/, 'kumamoto-public')
publicDirOnline = '/kumamoto-public/'

if $OPT[:online]
	pathStart = publicDirOnline
	pathEnd = ''
else
	pathStart = publicDir
	pathEnd = '/index.html'
end

def readAndEncode(f)
	if String.method_defined?(:encode)
		f.read.encode('UTF-8', 'UTF-8', :invalid => :replace)
	else
		ic = Iconv.new('UTF-8', 'UTF-8//IGNORE')
		ic.iconv(f.read)
	end
end

puts 'Publishing ' + ($OPT[:online] ? 'for the web' : 'locally')+".\n\n"
puts 'Public Dir: '+ publicDir
puts 'Public Dir Web: '+ publicDirOnline

header = '<html><body>'
footer = '</body></html>'
navbar = ''

File.open(pwd+"header.html") do |f|
	header = readAndEncode( f )
	header.gsub!(/{{pathStart}}/, pathStart)
	
end
File.open(pwd+"footer.html") do |f|
	footer = readAndEncode( f )
end
File.open(pwd+"navbar.html") do |f|
	navbar = readAndEncode( f )
	navbar.gsub!(/{{pathStart}}/, pathStart)
	navbar.gsub!(/{{pathEnd}}/, pathEnd)
end

['index', 'principios', 'propuestas', 'compromisos', 'kit', 'splash', 'privacidad'].each do |name|
	File.open(pwd+name+".html") do |f|
		html = readAndEncode(f)
		
		title = html.match(/^\s*title:(.*)$/)[1].strip

		header.gsub!(/{{title}}/, title)

		html.gsub!(/{{pathEnd}}/, pathEnd)
		html.gsub!(/{{pathStart}}/, pathStart)

		html.gsub!(/---.*?---/m, '')

		unless (File.exists?(publicDir+name) or (name=='index'))
			Dir.mkdir(publicDir+name)
		end
		unless name == 'index'
			header += navbar
		end
		publicHtml = publicDir+(name == 'index' ? 'index' : (name+'/index'))+'.html'
		File.open(publicHtml, "w+").write(
			header+html+footer
		)
		puts 'Published: '+name
	end
end
