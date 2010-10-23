#!/usr/bin/ruby
# Text paster
#   using RMagick Ver.0.1
#                    2010/03/05 Yasuki
#
require 'RMagick'
require 'optparse'
require 'pp'
include Magick

# 組み込み初期値
SIGNATURE      = "まぁるいしっぽ\n http://www.maarui.doorblog.jp"
SIGNATURESIZE  = 14
SIGSTROKE      = "none"
SIGPLACE       = 1
SIGNATUREFONT  = "/usr/share/fonts/truetype/ttf-japanese-gothic.ttf"
#TITLEFONT      = "/usr/share/fonts/truetype/ttf-japanese-gothic.ttf"
#TITLEFONT      = "/usr/share/fonts/truetype/thai/Purisa-BoldOblique.ttf"
TITLEFONT      = "/usr/share/fonts/truetype/freefont/GearBox.ttf"
TITLESIZE      = 40
TITLEFILL      = "Darkred"
TITLEPLACE     = 2

# 文字列を画像化するために必要な属性クラス
# decoの意味  0:普通  1:透明色  2:影付き
#
class TextToImgProperty
  attr_accessor :text, :pointsize
  attr_accessor :stroke, :fill, :font
  attr_accessor :place, :deco

  def get_place  # 数字で指定した場所から、gravityを返すメソッド
    case self.place
      when 0 then return Magick::CenterGravity     # 中心
      when 1 then return Magick::NorthWestGravity  # 左上
      when 2 then return Magick::NorthEastGravity  # 右上
      when 3 then return Magick::SouthWestGravity  # 左下
      when 4 then return Magick::SouthEastGravity  # 右下
      when 5 then return Magick::NorthGravity      # 上
      when 6 then return Magick::WestGravity       # 左
      when 7 then return Magick::EastGravity       # 右
      when 8 then return Magick::SouthGravity      # 下
    end
  end
end

# TextToImgPropertyクラスの情報を使って、画像に文字列を貼り付ける手順
#
module TextPaste  
  def textpaste( i, s )
    draw_obj = Magick::Draw.new
    draw_obj.font      = s.font       #フォント指定
    draw_obj.pointsize = s.pointsize  #フォントサイズ
    draw_obj.stroke    = s.stroke     #文字の縁取り色
    draw_obj.fill      = s.fill       #文字色
    draw_obj.gravity   = s.get_place

    case s.deco
      when 0 then
        draw_obj.annotate(i, 0, 0, 0, 0, s.text)

      when 1 then 
        #透明文字の作成
        draw_obj.fill = "black"
        tempimg = Magick::Image.new( i.columns, i.rows )
        draw_obj.annotate(tempimg, 0, 0, 0, 0, s.text)
        tempimg = tempimg.shade( true, 310, 30 )
        i.composite!( tempimg, 0, 0, Magick::HardLightCompositeOp)

      when 2 then
        # 影付き文字の作成
        # 文字のフロント部分描画
        imgSize = draw_obj.get_multiline_type_metrics(s.text)
        frontImg = Magick::Image.new(imgSize.width+10, imgSize.height+10){
          self.background_color = "none"
        }
        draw_obj.annotate(frontImg, 0, 0, 0, 0, s.text) {
          self.gravity = CenterGravity
        }
        
        # 影の描画
        draw_obj.fill = "#20202090"
        shadowImg = Magick::Image.new(imgSize.width+10, imgSize.height+10){
          self.background_color = "#ffffff00"
        }
        draw_obj.annotate(shadowImg, 0, 0, 4+s.pointsize*0.05, 4+s.pointsize*0.05, s.text) {
          self.gravity = CenterGravity
        }
        
        # 影をぼかす
        shadowImg = shadowImg.blur_channel(0, 1, AllChannels)

        # 重ね合わせ
        frontImg = shadowImg.composite(frontImg, Magick::CenterGravity, 0, 0, Magick::OverCompositeOp)

        # 元の画像と重ね合わせ
        i.composite!(frontImg, s.get_place, 10, 0, Magick::OverCompositeOp)
    end

  end
  module_function :textpaste
end

# コマンドラインからのオプションを記録し整理するクラス
class CommandLineOption
  attr_accessor :inputfile, :outputfile
  attr_accessor :sigflag, :s_deco, :s_fill
  attr_accessor :title, :t_fill, :t_stroke
  attr_accessor :t_pointsize, :t_place, :t_deco

  def initialize()
    @inputfile=""
    @outputfile=""
    @sigflag=0
    @s_deco=1
    @s_fill="black"
    @title=""
    @t_stroke="none"
    @t_pointsize=TITLESIZE
    @t_place=TITLEPLACE
    @t_deco=0
    @t_fill=TITLEFILL
  end
end

# オプションの解析の開始
optionStruct=CommandLineOption.new

opt=OptionParser.new
opt.banner="This program copies the text message and signature onto the image file."
opt.version="0.1"

opt.on("-o FILENAME", "--output", "Output file name.") { |v|
  optionStruct.outputfile=v
}
opt.on("-s [n]", "--signature", /[0-2]/, "The registered signature is put.\n\t\t\t\t\tn is decoration type.") { |v|
  optionStruct.sigflag=1
  optionStruct.s_deco=v.to_i
}
opt.on("-c colorname","--sigfill", "The color name of the signature letters." ) { |v|
  optionStruct.s_fill=v.to_s
}
opt.on("-t title","--title", "The title strings.") { |v|
  optionStruct.title=v.to_s
}
opt.on("-f colorname", "--titlefill","The color name of the title letters.") { |v|
  optionStruct.t_fill=v.to_s
}
opt.on("-k colorname", "--titlestroke","The color name of the title stroke.") { |v|
  optionStruct.t_stroke=v.to_s
}
opt.on("-d n", "--titledecoration", /[0-2]/, "A decoration type of The title.") { |v|
  optionStruct.t_deco=v.to_i
}
opt.on("-p pointsize", "--titlesize","The pointsize of the text letters.") { |v|
  optionStruct.t_pointsize=v.to_i
}
opt.on("-l n", "--titleplace", /[0-8]/ , "Where is the message put? 0 is Center.") { |v|
  optionStruct.t_place=v.to_i
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

# オプションとファイルのチェック
if ARGV[0]==nil then
  puts "The input file is not specified."
  exit 1
else
  optionStruct.inputfile=ARGV[0]
end

if optionStruct.outputfile=="" then
  puts opt
  puts "The output file is not specified."
  exit 1
end

if FileTest::exist?(optionStruct.outputfile) then
  puts "The output file is exist."
  exit 1
end

if (optionStruct.sigflag==0) && (optionStruct.title=="") then
  puts opt
  puts "No text."
  exit 1
end

#puts "Option Parse..."
#pp optionStruct
#puts ""

#------------------------------------------------
#
# 計算開始時刻の取得
st=Time.now

# 画像ファイルの読み込み
img = Magick::ImageList.new(optionStruct.inputfile)
img.strip!              # EXIF情報の消去

# titleの画像生成
if (optionStruct.title != "") then
  titleProperty           = TextToImgProperty.new
  titleProperty.text      = optionStruct.title
  titleProperty.pointsize = optionStruct.t_pointsize
  titleProperty.stroke    = optionStruct.t_stroke
  titleProperty.fill      = optionStruct.t_fill
  titleProperty.font      = TITLEFONT
  titleProperty.place     = optionStruct.t_place
  titleProperty.deco      = optionStruct.t_deco

  TextPaste::textpaste( img, titleProperty )
end

# Signitureの画像生成
if (optionStruct.sigflag==1) then
  sigProperty           = TextToImgProperty.new
  sigProperty.text      = SIGNATURE
  sigProperty.pointsize = SIGNATURESIZE
  sigProperty.stroke    = SIGSTROKE
  sigProperty.fill      = optionStruct.s_fill
  sigProperty.font      = SIGNATUREFONT
  sigProperty.deco      = optionStruct.s_deco
  sigProperty.place     = SIGPLACE

  # シグニチャとタイトルが重なった場合、シグニチャをずらす
  if (optionStruct.t_place==sigProperty.place) then
    sigProperty.place -= 1
    if (sigProperty.place<=0) then
      sigProperty.place=4
    end
  end

  TextPaste::textpaste( img, sigProperty )
end

# 画像ファイルの出力
img.write(optionStruct.outputfile)
puts "created #{optionStruct.outputfile}"

# 計算時間の表示
puts "time=#{Time.now - st}sec"

exit 0
