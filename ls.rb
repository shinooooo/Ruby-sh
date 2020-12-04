blue = 34
Dir.foreach('.') do |f|
  if File.directory?(f)
    printf("\e[#{blue}m%-10s\e[0m\t", f)
  else 
    printf("%-10s\t", f)
  end
end
