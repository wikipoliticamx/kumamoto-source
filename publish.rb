#!/usr/bin/env ruby
require 'optparse'
require 'rubygems'
require 'iconv' unless String.method_defined?(:encode) #because http://stackoverflow.com/questions/2982677/ruby-1-9-invalid-byte-sequence-in-utf-8

$OPT = { #Options
	:mode=>'serverless',
	:splashOnly=>false
}

OptionParser.new do|opts|
	opts.banner = "Usage: kupu [options]. Publish kumamoto-source into kumamoto-public."
	opts.on( '-m STR', '--mode STR', 'Publish with online paths. Default false.' ) do |m|
		$OPT[:mode] = m
	end
	opts.on( '--splashOnly', 'Only publish the splash page.' ) do |m|
		$OPT[:splashOnly] = true
	end
end.parse!

root = '/Users/bex/Dropbox/prjcts/else/wikipolitica/WEB/kumamoto-source/' #Dir.pwd+'/'
publicDir =  root.gsub(/kumamoto-source/, 'kumamoto-mx')

# smart defaults
header = '<html><body>'
footer = '</body></html>'
navbar = ''
$pathStar = ''
$pathEnd = ''

if $OPT[:mode] == 'github-path'
	$pathStart = '/kumamoto-mx/'
	$pathEnd = ''
elsif $OPT[:mode] == 'server'
	$pathStart = '/'
	$pathEnd = ''
elsif $OPT[:mode] == 'serverless'
	pathStart = publicDir
	$pathEnd = '/index.html'
end

def parse str
	if $OPT[:mode] == 'github'
		str.gsub!(/{{onlineOnly(Start|End)}}/, '')
	else
		str.gsub!(/{{onlineOnlyStart}}[\s\S]*?{{onlineOnlyEnd}}/x, '')
	end
	str.gsub!(/{{pathStart}}/, $pathStart)
	str.gsub!(/{{pathEnd}}/, $pathEnd)
	str
end


def readAndEncode f
	if String.method_defined?(:encode)
		out = f.read.encode('UTF-8', 'UTF-8', :invalid => :replace)
	else
		ic = Iconv.new('UTF-8', 'UTF-8//IGNORE')
		out = ic.iconv(f.read)
	end
	parse out
end

puts 'Publishing for ' + $OPT[:mode]+".\n\n"
puts 'Public Dir: '+ publicDir

File.open(root+"header.html") do |f|
	header = readAndEncode( f )
end
File.open(root+"footer.html") do |f|
	footer = readAndEncode( f )
end
File.open(root+"navbar.html") do |f|
	navbar = readAndEncode( f )
end

pages = if $OPT[:splashOnly]
	['splash', 'mapa-d10']
else
	['index', 'principios', 'propuestas', 'compromisos', 'kit', 'splash', 'privacidad']
end

pages.each do |name|
	File.open(root+name+".html") do |f|
		html = readAndEncode( f )
		title = html.match(/^\s*title:(.*)$/);
			title = title ? title[1].strip : '';
		standalone = html.match(/{{standalone}}/)
		headerTemp = header.gsub(/{{title}}/, title)
		html.gsub!(/---.*?---/m, '')

		unless (File.exists?(publicDir+name) or (name=='index'))
			Dir.mkdir(publicDir+name)
		end

		headerNavbar = headerTemp
		unless (name == 'index') or (name == 'splash')
			headerNavbar = headerTemp + navbar
		end

		publicHtml = publicDir+(
				(name == 'index') or ($OPT[:splashOnly] && name == 'splash')  ?
					'index' :
					(name+'/index')
		)+'.html'

		File.open(publicHtml, "w+").write(
			unless standalone
				headerNavbar+html+footer
			else
				html
			end
		)
		puts 'Published: '+name
	end
end
