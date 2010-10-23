#!/usr/bin/ruby
# Image File Resizer
#   using RMagick
#               ver.0.4  2010/03/11 Yasuki
#
require 'RMagick'
require 'optparse'
require 'pp'
include Magick

class CommandLine
  attr_accessor:height, :width
  attr_accessor:inputfile, :outputfile
  attr_accessor:rotate, :check

  def initialize
    @height=0
    @width=0
    @outputfile=""
    @rotate=""
    @check=0
  end
end     # of Class CommandLine

#--------------------------------------------------
# Do
option_struct=CommandLine.new

opt=OptionParser.new
  opt.banner="This program is resizer and rotater of a Image file."
  opt.version="0.4"

  opt.on("-x width(px)","--width", "Width px of a new image.") { |v|
    option_struct.width=v.to_i
  }
  opt.on("-y height(px)", "--height","Height px of a new image.") { |v|
    option_struct.height=v.to_i
  }
  opt.on("-o FILENAME", "--output", "Output file name.") { |v|
    option_struct.outputfile=v
  }
  opt.on("-r WAY", "--rotate", ["r","l"], "Image rotatate right or left.") { |v|
    option_struct.rotate=v
  }
  opt.on("-f", "--free", "The aspect ratio is made free. ") { |v|
    option_struct.check=1
  }
  opt.on_tail("-h", "--help", "Show this message.") { |v|
    puts opt
    exit 1
  }
  opt.on_tail("-v", "--version", "Show version.") { |v|
    puts opt.version
    exit 1
  }

opt.parse!(ARGV)
if ARGV[0]==nil then
  puts "The input file is not specified."
  exit 1
else
  option_struct.inputfile=ARGV[0]
end

if option_struct.outputfile=="" then
  puts "The output file is not specified."
  puts opt
  exit 1
end

if FileTest::exist?(option_struct.outputfile) then
  puts "The output file is exist."
  exit 1
end

puts "Option Parse..."
pp option_struct
puts ""

#------------------------------------------------
#
# 画像ファイルの読み込み
img = Magick::ImageList.new(option_struct.inputfile)
img.strip!                # EXIF情報の消去
x=img.columns
y=img.rows
p "Input img: x=#{x}, y=#{y}"

# 計算開始時刻の取得
st=Time.now

# 回転の実施
case option_struct.rotate
when "r" then
  img=img.rotate!(90)
when "l" then
  img=img.rotate!(-90)
end

# リサイズの実施
if (option_struct.width!=0) || (option_struct.height!=0) then 
  if option_struct.check==1 then
    img.resize!(option_struct.width,option_struct.height)
  else
    img.resize_to_fit!(option_struct.width, option_struct.height)
  end
end

# 画像ファイルの出力
img.write(option_struct.outputfile)

# 出力した画像の確認
img = Magick::ImageList.new(option_struct.outputfile)
x=img.columns
y=img.rows
p "Output img: x=#{x}, y=#{y}"

# 計算時間の表示
p "time=#{Time.now - st}sec"

exit 0
