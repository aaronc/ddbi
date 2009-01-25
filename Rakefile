SRC = FileList["dbi/**/*.d"]
TEST_SRC = FileList[SRC,"testddbi.d"]

file "testddbi.exe" => TEST_SRC do
	sh "dsss build testddbi.d"
end

task :test => ["testddbi.exe"] do
	sh "./testddbi"
end

task :default => ["test"]

DMD = RUBY_PLATFORM.match(/win/) ? "dmd_rake.bat" : "dmd"

def do_ddoc(docfile, f)
  sh "#{DMD} -version=DDoc -D -Dddocs/api -Df#{docfile} -c -odobjs #{f} docs/candy.ddoc docs/modules.ddoc"
  sh "chmod 644 docs/api/#{docfile}"
end

task :refdoc => SRC do
  modules = File.new("docs/modules.ddoc", File::CREAT|File::TRUNC|File::RDWR, 0644)
  modules.write("MODULES =\n");
  tempIndex = File.new("docs/DDBI.d", File::CREAT|File::TRUNC|File::RDWR, 0644)
  tempIndex.write("Ddoc<ul>\n");
  SRC.each do |f|
    modname = f.gsub(/\//, "\.")
    docfile = modname.gsub(/\.d/, "\.html")
    modname = modname.gsub!(/\.d/, "")
    modules.write("$(MODULE_FULL #{modname})\n");
    tempIndex.write("<li><a href='#{docfile}'>#{modname}</a></li>\n")
  end
  modules.close;
  tempIndex.write("</ul>");
  tempIndex.close
 
  SRC.each do |f|
    docfile = f.gsub(/\//, "\.")
    docfile = docfile.gsub!(/\.d/, "\.html")
    do_ddoc(docfile, f)    
  end
  do_ddoc("index.html", "docs/DDBI.d")
end
