require 'dxopal'
include DXOpal

#地面のy座標
GROUND_Y = 400

#プレイヤー画像を宣言
Image.register(:player, 'images/fish_blackbass2.png')

#リンゴ画像
Image.register(:apple, 'images/fish_wakasagi.png')

#爆弾画像
Image.register(:bomb, 'images/fishing_lure.png')

#釣り人画像
Image.register(:angler, 'images/fishing_bass_man2.png')

#吹き出し
Image.register(:fukidasi, 'images/e0144_1.png')

#効果音
Sound.register(:get, 'sounds/get.wav')
Sound.register(:explosion, 'sounds/explosion.wav')

# ゲームの状態を記憶するハッシュを追加
GAME_INFO = {
  scene: :title,  # 現在のシーン(起動直後は:title)
  score: 0      # 現在のスコア
}

#プレイヤーを表すクラスを定義
class Player < Sprite
  def initialize
    x = 280 #Window.width / 2
	y = GROUND_Y - Image[:player].height
	image = Image[:player]
	super(x, y, image)
	# 当たり判定を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 16]
  end
  
  #移動処理（self.xはuserクラス(self=自分自身)のxという変数という意味
  def update
    if Input.key_down?(K_LEFT) && self.x > 0
	  self.x -= 8
	elsif Input.key_down?(K_RIGHT) && self.x < (Window.width - Image[:player].width)
	  self.x += 8
	end
  end
end

class Item < Sprite
  def initialize(image)
	x = rand(Window.width - image.width) #x座標をランダムに決める
	y = 0
	super(x, y, image)
	#もしこの+4 がなければrand(ランダム)の値で０が来たときにアイテムが止まる。だから＋４にしている
	@speed_y = rand(7) + 3  #落ちる速さをランダムに決める
  end
  
  def update
    #フレームごとに更新される。なので更新されるたびに下降しY値が増えていく。
    self.y += @speed_y
	#y座標がWindow.heightより大きくなったら、画面外に出たということなので、vanishメソッドを呼んでこの画像を無効化
	if self.y > Window.height
	  self.vanish
	end
  end
end

# 加点アイテムのクラスを追加
class Apple < Item
  def initialize
    super(Image[:apple])
	# 衝突範囲を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 56]
  end
  
  # playerと衝突したとき呼ばれるメソッドを追加
  def hit
    #効果音
	Sound[:get].play
    self.vanish
    GAME_INFO[:score] += 10
  end
end

# 妨害アイテムのクラスを追加
class Bomb < Item
  def initialize
    super(Image[:bomb])
	# 衝突範囲を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 42]
  end
  
  # playerと衝突したとき呼ばれるメソッドを追加
  def hit
    # 効果音を鳴らす
    Sound[:explosion].play
    self.vanish
    GAME_INFO[:scene] = :game_over  # スコアを0点にする
  end
end

#アイテム群を管理するクラスを追加
class Items
  #同時に出現するアイテムの個数
  N = 5
  
  def initialize
    @items = []
  end
  
  def update(player)
    @items.each{|x| x.update(player)}
    # playerとitemsが衝突しているかチェックする。衝突していたらhitメソッドが呼ばれる
    Sprite.check(player, @items)
	#vanishしたスプライトを配列から取り除く
	#y座標の値がwindowのサイズを超えたアイテム
	Sprite.clean(@items)
	
	#消えた分を補填する（常にアイテムがN個あるようにする）
	#消えたアイテム数の回数、アイテムをふやす
	(N - @items.size).times do
      # どっちのアイテムにするか、ランダムで決める
      if rand(100) < 40
        @items.push(Apple.new)
      else
        @items.push(Bomb.new)
      end
    end
  end
  
  def draw
    #各スプライトのdrawメソッドを呼ぶ
	Sprite.draw(@items)
  end
end
	

Window.load_resources do
  
  player = Player.new
  
  #Itemsクラスのオブジェクトを作る
  items = Items.new
  
  Window.loop do
    #キー入力をチェック
	#player.update
	#アイテムの作成、移動、削除
	#items.update(player)
	
    #背景を描画
	#空カラー
	Window.draw_box_fill(0, 0, Window.width, GROUND_Y, [128, 255, 255])
	#地面カラー
	Window.draw_box_fill(0, GROUND_Y, Window.width, Window.height, [0, 128, 0])
	# スコアを画面に表示する
    Window.draw_font(0, 0, "SCORE: #{GAME_INFO[:score]}", Font.default, {:color => C_BLACK})
	
	#シーンごとの処理
	case GAME_INFO[:scene]
	when :title
	  #タイトル画面
	  Window.draw_font(0, 30, "PRESS SPACE", Font.default, {:color => C_BLACK})
	  Window.draw_font(100, 150, "ワカサギ", Font.default, {:color => C_BLACK})
	  Window.draw_font(450, 150, "ルアー", Font.default, {:color => C_BLACK})
	  Window.draw_font(100, 250, "ワカサギを食べてルアーには食い付くな！", Font.default, {:color => C_BLACK})
	  image1 = Image[:apple]
	  image2 = Image[:bomb]
	  Window.draw(100, 100, image1)
	  Window.draw(450, 100, image2)
	  player.draw
	  #スペースキーが押されたらシーンを変える
	  if Input.key_push?(K_SPACE)
	    GAME_INFO[:scene] = :playing
	  end
	when :playing
	  player.update
	  items.update(player)
	  
	  player.draw
	  items.draw
	when :game_over
	  #ゲームオーバー画面
	  Window.draw_font(0, 30, "PRESS SPACE", Font.default, {:color => C_BLACK})
	  image3 = Image[:angler]
	  Window.draw(150, 100, image3)
	  image4 = Image[:fukidasi]
	  Window.draw(450, 140, image4)
	  #player.draw
	  #items.draw
	  #スペースキーが押されたらゲームの状態をリセットし、シーンを変える
	  if Input.key_push?(K_SPACE)
	    player = Player.new
		items = Items.new
		GAME_INFO[:score] = 0
		GAME_INFO[:scene] = :playing
	  end
	end
  end
end