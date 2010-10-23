#!/usr/bin/ruby
# Image Triming
#   using RMagick
#               ver.0.1  2010/03/12 Yasuki
#
require 'RMagick'
require 'optparse'
require 'pp'
include Magick

class CommandLine
  attr_accessor:x, :y, :point
  attr_accessor:switch
  attr_accessor:inputfile, :outputfile

  def initialize
    @x=0
    @y=0
    @outputfile=""
    @switch="a"
    @point=0
  end

  def getPoint  # 数字で指定した場所から、gravityを返すメソッド
    case self.point
      when 0 then return Magick::CenterGravity     # 中心
      when 1 then return Magick::NorthWestGravity  # 左上
      when 2 then return Magick::NorthEastGravity  # 右上
      when 3 then return Magick::SouthWestGravity  # 左下
      when 4 then return Magick::SouthEastGravity  # 右下
    end
  end

end     # of Class CommandLine

#--------------------------------------------------
#
optionStruct=CommandLine.new

opt=OptionParser.new
  opt.banner="This program is triming cutter of a Image file."
  opt.version="0.1"

  opt.on("-x n","--width", "Width of a new image.") { |v|
    optionStruct.x=v.to_i
  }
  opt.on("-y n", "--height","Height of a new image.") { |v|
    optionStruct.y=v.to_i
  }
  opt.on("-o FILENAME", "--output", "Output file name.") { |v|
    optionStruct.outputfile=v
  }
  opt.on("-l n", "--point", /[0-4]/, "Stating point.") { |v|
    optionStruct.point=v.to_i
  }
  opt.on("-a", "--aspect", "The value is the Aspect ratio. ") { |v|
    optionStruct.switch="a"
  }
  opt.on("-r", "--ratio", "The value is the ratio. ") { |v|
    optionStruct.switch="r"
  }
  opt.on("-p", "--pixel", "The value is the pixels. ") { |v|
    optionStruct.switch="p"
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
  optionStruct.inputfile=ARGV[0]
end

if optionStruct.outputfile=="" then
  puts "The output file is not specified."
  puts opt
  exit 1
end

if FileTest::exist?(optionStruct.outputfile) then
  puts "The output file is exist."
  exit 1
end

if optionStruct.x==0 || optionStruct.y==0 then
  puts "x and y is zero."
  exit 1
end

#puts "Option Parse..."
#pp optionStruct
#pp optionStruct.getPoint
#puts ""

#------------------------------------------------
#
# 画像ファイルの読み込み
img = Magick::ImageList.new(optionStruct.inputfile)
img.strip!                # EXIF情報の消去
originalx=img.columns
originaly=img.rows
puts "Input img: x=#{originalx}, y=#{originaly}, x/y=#{
 originalx/originaly.to_f}"
if optionStruct.switch=="a" then
  puts "requiment: #{optionStruct.x}:#{optionStruct.y} = #{
   optionStruct.x/optionStruct.y.to_f}"
end
if optionStruct.switch=="p" then
  puts "requiment: #{optionStruct.x}pt : #{optionStruct.y
    }pt = #{optionStruct.x/optionStruct.y.to_f}"
end
if optionStruct.switch=="r" then
  puts "requiment: #{optionStruct.x}%:#{optionStruct.y
    }% = #{(optionStruct.x/100.0)*originalx}pt:#{
    (optionStruct.y / 100.0)*originaly}pt = #{
    (optionStruct.x / 100.0)*originalx/
     ((optionStruct.y/100.0)*originaly)}"
end

# 計算開始時刻の取得
st=Time.now

# 切り抜き画像のサイズ決定
case optionStruct.switch
  # 整数比を与えられたときの、完成サイズの算出
  when "a" then
    originalAR=originalx/originaly.to_f
    cutAR=optionStruct.x/optionStruct.y.to_f
    if originalAR < 1 then
      if cutAR <1 then
        if originalAR < cutAR then
          width  = originaly * cutAR
          height = originaly
        else
          width  = originalx
          height = originalx * cutAR
        end
      else
        width  = originalx
        height = originalx * cutAR
      end
    else
      if cutAR >= 1 then
        if originalAR < cutAR then
          width  = originalx
          height = originalx * cutAR
        else
          width  = originaly * cutAR
          height = originaly
        end
      else
        width  = originaly * cutAR
        height = originaly
      end
    end

  # 辺に対する比率を与えられたときのサイズの算出
  when "r" then
    width=originalx*optionStruct.x/100
    height=originaly*optionStruct.y/100

  # 辺のピクセル長を与えられたとき
  when "p" then
    width=optionStruct.x
    height=optionStruct.y
end

# 切り抜きの実施
img.crop!( optionStruct.getPoint, 0, 0, width, height)

# 画像ファイルの出力
img.write(optionStruct.outputfile)

# 出力した画像の確認
img = Magick::ImageList.new(optionStruct.outputfile)
x=img.columns
y=img.rows
puts "Output img: x=#{x}, y=#{y}, x/y=#{x/y.to_f}"

# 計算時間の表示
puts "time=#{Time.now - st}sec"

exit 0

# 代表的なアスペクト比
#
# プリントサイズ  縦横比
# Ｌ              5:7
# ＤＳＣ          3:4
# KG （はがき）   2:3
# ハイビジョン    9:16
# P （パノラマ）  1:2.85
# ２Ｌ            5:7
# ＤＳＣＷ        3:4
# 六切            4:5
# Ａ５            1:√2
# 六切ワイド      2:3
# Ａ４            1:√2
# 四切            5:6
# 四切ワイド      2:3
# 自分のデジカメ  2:3
