class List
  require 'optparse'
  require 'etc'
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
      parsed_info = []
      fs = File::Stat.new(file)
      parsed_stmode = ""
      stmode = "%o" % fs.mode
      if stmode.length == 6
        case stmode[0,2] 
        when "14"
          parsed_stmode.concat("s")
        when "12"
          parsed_stmode.concat("l")
        when "10"
          parsed_stmode.concat("-")
        end
        stmode = stmode[3,3]
      else
        case stmode[0,1]
        when "6"
         parsed_stmode.concat("b")
        when "4"
          parsed_stmode.concat("d")
        when "2"
          parsed_stmode.concat("c")
        when "1"
          parsed_stmode.concat("p")
        when "0"
          parsed_stmode.concat("?")
        end
        stmode = stmode[2,3]
      end
      permissions = stmode.chars.map{ |c| ("%b" % c).delete_prefix("0b0").chars }
      permissions.each do |permission| 
        parsed_stmode.concat(permission.shift == '1' ? "r" : "-")
        parsed_stmode.concat(permission.shift == '1' ? "w" : "-")
        parsed_stmode.concat(permission.shift == '1' ? "x" : "-")
      end
      parsed_info.push(parsed_stmode)
      
      # TODO:add access control list
      
      parsed_info.push(fs.nlink)
      owner = Etc.getpwuid(fs.uid).name
      parsed_info.push(owner)
      group = Etc.getgrgid(fs.gid).name
      parsed_info.push(group)

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

