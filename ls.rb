class ListSegments
  require 'optparse'
  require 'etc'

  def self.exec
    @options = {}
    OptionParser.new do |o|
      o.on("-a","like \"ls -a\""){ @options[:all] = true } 
      o.on("-l","like \"ls -l\"") { @options[:long] = true }
      o.parse!(ARGV)
    end

    args = get_args
    multi_flag =  args.count >= 2 ? true : false
    dirs = args.count != 0 ? validate_args(args) : ["."]
    dirs.each do |dir|
      display(dir, multi_flag)
    end
  end
  
  private
  def self.get_args
    ARGV
  end

  def self.validate_args(args)
    valid_dir = []
    args.each do |arg|
      if Dir.exist?(arg)
        valid_dir.push(arg)
      else
        printf("%s: %s: No such file or directory\n", $0, arg)
      end
    end
    valid_dir
  end

  def self.display(dir, multi_flag)
    printf("%s:\n", dir) if multi_flag
    if @options[:long]
      display_list(get_path(dir))
    else
      display_normal(get_path(dir))
    end
  end

  def self.display_list(dir)
    total_blocks = 0

    files = get_files(dir)
    lists = []
    files.each do |file|
      parsed_info = []
      fs = File::Stat.new("#{dir}/#{file}")

      total_blocks += fs.blocks

      parsed_info.push(get_mode(fs))
      
      parsed_info.push(get_nlink(fs))

      parsed_info.push(get_owner(fs))

      parsed_info.push(get_group(fs))

      parsed_info.push(get_size(fs))

      date, time = get_time(fs)
      parsed_info.push(date)
      parsed_info.push(time)

      parsed_info.push(file)

      lists.push(parsed_info)
    end
      print_list(lists, total_blocks)
  end

  def self.get_mode(fs)
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
     parsed_mode
     # TODO:add access control list
  end

  def self.get_nlink(fs)
    nlink = fs.nlink.to_s
  end

  def self.get_owner(fs)
    owner = Etc.getpwuid(fs.uid).name
  end
  
  def self.get_group(fs)
    group = Etc.getgrgid(fs.gid).name
  end

  def self.get_size(fs)
    size = fs.size.to_s
  end

  def self.get_time(fs)
    mtime = fs.mtime
    month = mtime.strftime("%m")
    month[0] = (" ") if month[0] == '0'
    day = mtime.strftime("%e")
    date = month.concat(" ",day)

    half_year = 15552000
    if (mtime - Time.now).abs >= half_year
      year = mtime.year.to_s
      return date, year
    else
      time = mtime.strftime("%R")
      return date, time
    end
  end
  
  def self.print_list(lists,total_blocks)
    print("total #{total_blocks.to_s}\n")

    block_len = 1
    owner_len = 1
    group_len = 1
    size_len = 1
    time_len = 1
    
    lists.map { |info| 
                      block_len = info[1].length if block_len < info[1].length 
                      owner_len = info[2].length if owner_len < info[2].length
                      group_len = info[3].length if group_len < info[2].length
                      size_len = info[4].length if size_len < info[4].length 
                      time_len = info[6].length if time_len < info[6].length
              }

    lists.each do |info|
      printf("%s %#{block_len + 1}s %-#{owner_len}s  %-#{group_len}s %#{size_len + 1}s %s %#{time_len}s %s\n",
             info[0], info[1], info[2], info[3], info[4], info[5], info[6], info[7])
    end
  end

  def self.display_normal(dir) 
    
    files = get_files(dir)
    files_count = files.length

    name_len = 1
    files.map { |file| name_len = file.length if name_len < file.length }

    total_length = (name_len + 5) * files.count
    # case ls -G: total_length = (name_len + 1) * files.count
    columns = `tput cols`.to_i

    line_count = (total_length + (columns - 1)) / columns
    column_count = (files.count + (line_count / 2)) / line_count
    line_count = 1 if line_count == 0


    (0...line_count).each do |line|
      (0...column_count).each do |column|
        idx = line_count * column + line
        printf("%-#{name_len}s\t", files[idx]) if idx < files_count
        # case ls -G: printf("%-#{name_len + 1}s", files[idx]) if idx < files_count
      end
      print("\n")
    end
  end

  def self.get_path(dir)
    Dir.chdir(dir) do
      dir = Dir.pwd
    end
  end

  def self.get_files(dir)
    @options[:all] ? Dir.entries(dir).sort : Dir.children(dir).filter{ |file| file[0] != "." }.sort
  end
end

ListSegments.exec
