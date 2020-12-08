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
    total_blocks = 0

    files = Dir.children(dir).filter{ |file| file[0] != "." }.sort
    files.each do |file|
      parsed_info = []
      fs = File::Stat.new(file)

      total_blocks += fs.blocks

      parsed_mode = ""
      mode = "%o" % fs.mode
      if mode.length == 6
        case mode[0,2] 
        when "14"
          parsed_mode.concat("s")
        when "12"
          parsed_mode.concat("l")
        when "10"
          parsed_mode.concat("-")
        end
        mode = mode[3,3]
      else
        case mode[0,1]
        when "6"
         parsed_mode.concat("b")
        when "4"
          parsed_mode.concat("d")
        when "2"
          parsed_mode.concat("c")
        when "1"
          parsed_mode.concat("p")
        when "0"
          parsed_mode.concat("?")
        end
        mode = mode[2,3]
      end
      permissions = mode.chars.map{ |c| ("%b" % c).delete_prefix("0b0").chars }
      permissions.each do |permission| 
        parsed_mode.concat(permission.shift == '1' ? "r" : "-")
        parsed_mode.concat(permission.shift == '1' ? "w" : "-")
        parsed_mode.concat(permission.shift == '1' ? "x" : "-")
      end
      parsed_info.push(parsed_mode)
      
      # TODO:add access control list
      
      nlink = fs.nlink
      parsed_info.push(fs.nlink)

      owner = Etc.getpwuid(fs.uid).name
      parsed_info.push(owner)

      group = Etc.getgrgid(fs.gid).name
      parsed_info.push(group)

      size = fs.size
      parsed_info.push(size)

      ctime = fs.ctime

      month = ctime.strftime("%m")
      month[0] = (" ") if month[0] == '0'
      day = ctime.strftime("%e")
      date = month.concat(" ",day)
      parsed_info.push(date)

      half_year = 15552000
      if (ctime - Time.now).abs >= half_year
        # It needs to be fixed when year becomes 5 digits.
        year = "%5s" % ctime.year.to_s
        parsed_info.push(year)
      else
        time = ctime.strftime("%R")
        parsed_info.push(time)
      end
      parsed_info.push(file)
      p parsed_info
    end
    p "total " + total_blocks.to_s
  end

  def display_common(dir) 
    files =  @options[:all] ? Dir.entries(dir).sort : Dir.children(dir).filter{ |file| file[0] != "." }.sort
    files.each do |file|
      if File.directory?(file)
        printf("\e[#{@@dir_color}m%-10s\e[0m\t", file)
      elsif File.symlink?(file)
        printf("\e[45m%-10s\e[0m\t", file)
      else
        printf("%-10s\t", file)
      end
      # p File.ftype(file)
    end
    print("\n")
  end
end

list = List.new
list.exec

