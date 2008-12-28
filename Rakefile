SRC = FileList["dbi/**/*.d", "testddbi.d"]

file "testddbi.exe" => SRC do
	sh "dsss build testddbi.d"
end

task :test => ["testddbi.exe"] do
	sh "./testddbi"
end

task :default => ["test"]
