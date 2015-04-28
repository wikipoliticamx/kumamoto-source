#!/usr/bin/env ruby
# encoding: utf-8
require 'optparse'
require 'rubygems'
#require 'htmlentities'
#require 'unicode'
require 'iconv' unless String.method_defined?(:encode) #because http://stackoverflow.com/questions/2982677/ruby-1-9-invalid-byte-sequence-in-utf-8
#ruby -run -ehttpd . -p8000

#$KCODE = 'UTF-8'

$OPT = { #Options
	:mode=>'server',
	:test=>false
	#:splashOnly=>false
}

OptionParser.new do|opts|
	opts.banner = "Usage: kupu [options]. Publish kumamoto-source into kumamoto-public."
	opts.on( '-m STR', '--mode STR', 'Publish with online paths. Default false.' ) do |m|
		$OPT[:mode] = m
	end
	#opts.on( '-t', '--test', 'Publish whole site under test subdirectory.' ) do
		#$OPT[:test] = true
	#end
	#opts.on( '--splashOnly', 'Only publish the splash page.' ) do |m|
		#$OPT[:splashOnly] = true
	#end
end.parse!

root = '/Users/bex/Dropbox/prjcts/else/wikipolitica/WEB/kumamoto-source/' #Dir.pwd+'/'
publicDir =  root.gsub(/kumamoto-source/, 'kumamoto-mx')+($OPT[:test] ? 'test/' : '')

# smart defaults
head = '<html><body>'
footer = '</body></html>'
header = ''
navbar = ''
redirect = ''
$pathStar = ''
$pathEnd = ''

if $OPT[:mode] == 'github-path'
	$pathStart = '/kumamoto-mx/'
	$pathEnd = ''
elsif $OPT[:mode] == 'server'
	$pathStart = '/'
	$pathEnd = ''
elsif $OPT[:mode] == 'server'
	$pathStart = '/'
	$pathEnd = ''
elsif $OPT[:mode] == 'serverless'
	pathStart = publicDir
	$pathEnd = '/index.html'
end

def parse str
	if $OPT[:mode] == 'server'
		str.gsub!(/{{onlineOnly(Start|End)}}/, '')
	else
		str.gsub!(/{{onlineOnlyStart}}[\s\S]*?{{onlineOnlyEnd}}/x, '')
	end
	str.gsub!(/{{pathStart}}/, $pathStart)
	str.gsub!(/{{pathEnd}}/, $pathEnd)
	str.gsub!(/{{test}}/, $OPT[:test] ? 'test/' : '')
	str
end


def readAndEncode f
	if String.method_defined?(:encode)
		out = f.read.encode('UTF-8', 'UTF-8', :invalid => :replace, :replace => '')
	#else
		#ic = Iconv.new('UTF-8', 'UTF-8//IGNORE')
		#out = ic.iconv(f.read)
	end
	parse out
end

puts 'Publishing for ' + $OPT[:mode]+".\n\n"
puts 'Public Dir: '+ publicDir

File.open(root+"head.html") do |f|
	head = readAndEncode( f )
end
File.open(root+"footer.html") do |f|
	footer = readAndEncode( f )
end
File.open(root+"navbar.html") do |f|
	navbar = readAndEncode( f )
end
File.open(root+"header.html") do |f|
	header = readAndEncode( f )
end
File.open(root+"redirect.html") do |f|
	redirect = readAndEncode( f )
end


def readProp(prop, html)
	out = html.match(/^\s*#{prop}:(.*)$/);
	out ? out[1].strip : '';
end

sectionData = {
	'inteligencia-colectiva'=>['Inteligencia Colectiva', 'Creemos que mientras más personas estén involucradas en una toma de decisión o el desarrollo de una idea, mejor será el resultado.'],
	'participacion-ciudadana'=>['Participación Ciudadana', 'Las personas deben ser las protagonistas de la democracia.'],
	'apertura'=>['Apertura', 'Reconocemos en la crítica y la oposición una de las fuentes de construcción política más importantes.'],
	'innovacion'=>['Innovación', 'Solo apalancándonos de nuevas herramientas e ideas podremos lograr cambios radicales en nuestro sistema político.'],
	'perspectiva-de-genero'=>['Perspectiva de género', 'Queremos construir una sociedad que deje atrás el discurso heteronormativo patriarcal.'],
	'derechos-humanos'=>['Derechos Humanos', 'Defenderemos los derechos humanos y lucharemos por extenderlos.'],
	'transparencia'=>['Transparencia', 'Toda la información del quehacer legislativo debe ser un bien público.'],

	'ocupemos-la-ciudad'=>['Ocupemos la ciudad', 'Ocupar la ciudad es recuperar para las personas el espacio en el que viven. Creemos que el distrito 10 puede ser la vanguardia.'],
	'ciudad-democratica'=>['Ciudad democrática', 'Los problemas de la democracia se resuelven con más democracia.'],
	'ciudad-sostenible'=>['Ciudad sostenible', 'Una ciudad sostenible es una ciudad con futuro. La zona metropolitana de Guadalajara es el segundo núcleo urbano más grande de México y es urgente tomar medidas para hacer frente a los enormes retos sociales, económicos y ecológicos que toda mega urbe tiene.'],
	'ciudad-incluyente'=>['Ciudad incluyente', 'La gran tarea de nuestra generación es construir ciudades donde quepan todas y todos.'],
	'habitemos-el-gobierno'=>['Habitemos el gobierno', 'Habitar el gobierno es ponerle un alto al gobierno de los cínicos y recuperar las riendas de nuestro futuro. Mostrar todo lo que puede hacer un servidor público que ponga primero los intereses de las personas, esa es mi meta como diputado.'],
	'gobernar-con-las-personas'=>['Gobernar con las personas', 'Limitar la participación de las personas al voto es absurdo en un mundo con herramientas tan complejas como el nuestro.'],
	'servicio-publico-de-excelencia'=>['Servicio público de excelencia', 'No basta que un representatne sólo cumpla sus tareas mínimas, hay que exigirle excelencia.'],
	'contrapeso-al-ejecutivo'=>['Contrapeso al ejecutivo', 'El diputado es el principal encargado de vigilar que el trabajo de las autoridades ejecutivas sea real y acorde a la ley.'],

	'en-campanha'=>['En campaña', 'Queremos reivindicar el quehacer político a través de las formas y los fondos. Estos son mis compromisos desde el primer día de campaña.'],
	'quien-iba-a-creer'=>['Quien iba a creer', 'A los que no creían y que aún no creen prefiero decirles que <strong>esto ya empezó</strong>, que podemos decir con seguridad que hoy ya está mejor y que va a estar mejor cuando decidan creer y se sumen'],
	'en-el-congreso'=>['En el congreso', 'Queremos reivindicar el quehacer político a través de las formas y los fondos. Estos son mis compromisos durante mi periodo legislativo.']
}

pages = ['index', 'principios', 'propuestas', 'compromisos', 'kit', 'privacidad']

pages.each do |page|
	File.open(root+page+".html") do |f|
		html = readAndEncode( f )
		
		standalone = html.match(/{{standalone}}/)

		# FRONT MATTER
		title = readProp('title', html);
		headTemp = head.gsub(/{{title}}/, title);

		og_url = readProp('og_url', html);
		headTemp = headTemp.gsub(/{{og_url}}/, og_url);

		og_description = readProp('og_description', html);
		headTemp = headTemp.gsub(/{{og_description}}/, og_description);

		og_image = readProp('og_image', html);
		headTemp = headTemp.gsub(/{{og_image}}/, og_image);
		

		html.gsub!(/---.*?---/m, '') #trim front matter

		html = html.sub(/{{navbar}}/, navbar).sub(/{{header}}/, header)

		unless (File.exists?(publicDir+page) or (page=='index'))
			Dir.mkdir(publicDir+page)
		end

		if(['principios', 'propuestas', 'compromisos'].include?(page))
			html.scan(/data-menuanchor="([^"]+)"/) do |section| section = section[0]
				thisSectionData = sectionData[section]
				if section != 'inicio'
					sectionDir = publicDir+page+'/'+section
					unless File.exists?( sectionDir )
						Dir.mkdir( sectionDir )
					end

					redirectTemp = redirect.gsub(/{{title}}/, thisSectionData[0]+' | Mis '+page+' | Pedro Kumamoto').
						gsub(/{{og_image}}/, 'img/screenshots/'+page+'-'+section+'.jpg').
						gsub(/{{og_url}}/, page+'/'+section+'/').
						gsub(/{{og_description}}/, thisSectionData[1]).
						gsub(/{{redirectUrl}}/, page+'#'+section).
						gsub(/{{redirectText}}/, '<h1>Mis '+page+' - '+thisSectionData[0]+'</h1>')

					File.open(sectionDir+'/index.html', "w+").write(redirectTemp)
				end
			end
		end

		#if($OPT[:test])
			#publicHtml = (page == 'splash' ? publicDir.gsub(/test\//,'') : publicDir)+(
					#(page == 'index' or page=='splash') ?
						#'index' :
						#(page+'/index')
			#)+'.html'
		#else
		publicHtml = publicDir+(
				(page == 'index') ?
					'index' :
					(page+'/index')
		)+'.html'

		File.open(publicHtml, "w+").write(
			unless standalone
				headTemp + html + footer
			else
				html
			end
		)
		puts 'Published: '+page
	end
end
