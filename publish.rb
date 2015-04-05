require 'rubygems'
require 'iconv' unless String.method_defined?(:encode) #because http://stackoverflow.com/questions/2982677/ruby-1-9-invalid-byte-sequence-in-utf-8

pwd = Dir.pwd+'/'
publicDir =  pwd.gsub(/kumamoto-source/, 'kumamoto-public')

def readAndEncode(f)
	if String.method_defined?(:encode)
		f.read.encode('UTF-8', 'UTF-8', :invalid => :replace)
	else
		ic = Iconv.new('UTF-8', 'UTF-8//IGNORE')
		ic.iconv(f.read)
	end
end

header = '<html><body>'
footer = '</body></html>'
navbar = ''

File.open(pwd+"header.html") do |f|
	header = readAndEncode( f )
	header.gsub!(/{{localStart}}/, publicDir)
	
end
File.open(pwd+"footer.html") do |f|
	footer = readAndEncode( f )
end
File.open(pwd+"navbar.html") do |f|
	navbar = readAndEncode( f )
	navbar.gsub!(/{{localStart}}/, publicDir)
	navbar.gsub!(/{{localEnd}}/, '/index.html')
end

puts 'pwd: '+pwd
['index', 'principios', 'propuestas', 'compromisos', 'kit'].each do |name|
	File.open(pwd+name+".html") do |f|
		html = readAndEncode(f)
		
		title = html.match(/^\s*title:(.*)$/)[1].strip

		header.gsub!(/{{title}}/, title)

		html.gsub!(/{{localEnd}}/, '/index.html')
		html.gsub!(/{{localStart}}/, publicDir)


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
