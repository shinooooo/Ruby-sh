class List
  require 'optparse'
  def initialize
    @options = {}
    OptionParser.new do |o| 
    o.on("-a","like \"ls -a\""){ @options[:all] = true } 
    o.on("-l","like \"ls -l\"") { @options[:long] = true}
    o.parse!(ARGV)
    end
  end

  def exec
    options = get_arg
    dirs = validate(options)
    multi_flag =  dirs.count > 2 ? true : false

    dirs.each do |dir|
      display(dir,multi_flag)
    end
  end
  
  private
  def get_arg
    ARGV
  end

  def validate(options)
    valid_dir = []
    options.each do |option|
      if Dir.exist?(option)
        valid_dir.push(option)
      else
        printf("%s: %s: No such file or directory\n",$0 ,option)
      end
    end
    valid_dir
  end

  def display(dir,multi_flag)
    printf("%s:\n", dir) if multi_flag
    dir_color = 34
    Dir.foreach(dir) do |f|
      if File.directory?(f)
        printf("\e[#{dir_color}m%-10s\e[0m\t", f)
      else 
        printf("%-10s\t", f)
      end
      print("\n")
    end
  end
end

list = List.new
list.exec
