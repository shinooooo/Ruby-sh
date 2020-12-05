class List
  require 'optparse'
  @@dir_color = 34
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
    dirs = options.count != 0 ? validate(options) : ["."]
    multi_flag =  dirs.count > 2 ? true : false
    dirs.each do |dir|
      display(dir, multi_flag)
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
    if @options[:long]
      display_list(dir)
    else
      display_common(dir)
    end
  end

  def display_list(dir)
    files = Dir.children(dir).filter{ |file| file[0] != "." }
    # printf("total %s\n", );
    files.each do |file|
      case File.ftype(file)
      when "file"
        stmode = "-"
      when "directory"
        stmode = "d"
      when "characterSpecial"
        stmode = "c"
      when "blockSpecial"
        stmode = "b"
      when "fifo"
        stmode = "p"
      when "link"
        stmode = "l"
      when "socket"
        stmode = "s"
      else
        stmode = "?"
      end

      permission = ("%#b" % File.stat(file).world_readable?).delete_prefix("0b")
      permission = permission.chars
      p permission
      (0..2).each {
        stmode.concat(permission.shift == '1' ? "r" : "-")
        stmode.concat(permission.shift == '1' ? "w" : "-")
        stmode.concat(permission.shift == '1' ? "x" : "-")
      }
      p stmode

    end

  end

  def display_common(dir) 
    files =  @options[:all] ? Dir.entries(dir) : Dir.children(dir).filter{ |file| file[0] != "." }
    files.each do |file|
      if File.directory?(file)
        printf("\e[#{@@dir_color}m%-10s\e[0m\t", file)
      elsif File.symlink?(file)
        printf("\e[45m%-10s\e[0m\t", file)
      else
        printf("%-10s\t", file)
      end
      p File.ftype(file)
    end
    print("\n")
  end
end

list = List.new
list.exec

