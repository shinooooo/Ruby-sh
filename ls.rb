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
    args = get_args
    dirs = args.count != 0 ? validate_args(args) : ["."]
    multi_flag =  dirs.count > 2 ? true : false
    dirs.each do |dir|
      display(dir, multi_flag)
    end
  end
  
  private
  def get_args
    ARGV
  end

  def validate_args(args)
    valid_dir = []
    args.each do |arg|
      if Dir.exist?(arg)
        valid_dir.push(arg)
      else
        printf("%s: %s: No such file or directory\n",$0 ,arg)
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

    Dir.chdir(dir) do
      dir = Dir.pwd
    end
    files = Dir.children(dir).filter{ |file| file[0] != "." }.sort
    lists = []
    files.each do |file|
      parsed_info = []
      fs = File::Stat.new("#{dir}/#{file}")

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
      
      nlink = fs.nlink.to_s
      parsed_info.push(nlink)

      owner = Etc.getpwuid(fs.uid).name
      parsed_info.push(owner)

      group = Etc.getgrgid(fs.gid).name
      parsed_info.push(group)

      size = fs.size.to_s
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
      lists.push(parsed_info)
    end
      print_list(lists,total_blocks)
  end
  
  def print_list(lists,total_blocks)
    print("total #{total_blocks.to_s}\n")
    block_len = 1
    owner_len = 1
    group_len = 1
    size_len = 1
    lists.map { |info| 
                      block_len = info[1].length if block_len < info[1].length 
                      owner_len = info[2].length if owner_len < info[2].length
                      group_len = info[3].length if group_len < info[2].length
                      size_len = info[4].length if size_len < info[4].length 
              }

    lists.each do |info|
      printf("%s %#{block_len + 1}s %-#{owner_len}s  %-#{group_len}s %#{size_len + 1}s %s %s %s\n",
             info[0], info[1], info[2], info[3], info[4],info[5],info[6],info[7])
    end
  end

  def display_common(dir) 
    columns = `tput cols`.to_i
    Dir.chdir(dir) do
      dir = Dir.pwd
    end
    files =  @options[:all] ? Dir.entries(dir).sort : Dir.children(dir).filter{ |file| file[0] != "." }.sort
    name_len = 1
    files.map { |file| name_len = file.length if name_len < file.length }
    column_count = columns / (name_len + 1)
    line_count = files.count/column_count
    line_count = 1 if line_count
    (0...line_count).each do |line|
      (0...column_count).each do |column|
        # p line_count * column + line
        printf("%-#{name_len+1}s", files[line_count * column + line])
      end
      print("\n")
    end
  end
end

list = List.new
list.exec
