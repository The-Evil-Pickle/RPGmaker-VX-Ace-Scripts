#==============================================================================
# 
# ▼ TFLayers
# -- Last Updated: 2022.01.13
# -- Creator: The_Evil_Pickle
# -- Requires: 
#   --Yanfly's Ace Core Engine
#   --Yanfly's Ace Battle Engine + Kinu Extension
#   --Yanfly's Ace Message System
#   --Levi Stepp's Enhanced Save
# 
# Instructions: Put this below the other stuff in Materials
#==============================================================================
# -----------------------------------------------------------------------------
# Actor Notetags - These notetags go in the actors notebox in the database.
# -----------------------------------------------------------------------------
# <face layers>
#  string
#  string
# </face layers>
# A list of the images to layer on top of each other for this actor's face
# the strings should be name of the file you want, minus the name of the actor's
# base file. so if you want the file "myactor_hair_red" and the base file name
# is "myactor", the string here should be "_hair_red"
# To leave an empty layer, use the string "nil"; that layer will not render
# until changed to something else
# 
# <face base: string>
# Defines the base file for this actor's face. if not defined, it defaults to
# whatever you have assigned in the data
# 
# <body layers>
#  string
#  string
# </body layers>
# Works the same way as <face layers>, but defines the sprites to layer for the
# actor's walking around sprite. Uses the actor's default character file as the
# base file.
# Remember layers should be set to "nil" when not in use.



#leave the rest of this alone pls
module TKK
  module ACTOR
    FACE_LAYERS_ON  = /<(?:FACE_LAYERS|face layers)>/i
    FACE_LAYERS_OFF = /<\/(?:FACE_LAYERS|face layers)>/i
    BODY_LAYERS_ON  = /<(?:BODY_LAYERS|body layers)>/i
    BODY_LAYERS_OFF = /<\/(?:BODY_LAYERS|body layers)>/i
    FACE_BASE = /<(?:FACE_BASE|face base):[ ](.*)>/i
    BUILD_FACE_ID = "BUILDACTORFACE"
  end # ACTOR
end # TKK



#==============================================================================
# ■ DataManager
#==============================================================================

module DataManager
  
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_tfl load_database; end
  def self.load_database
    load_database_tfl
    load_notetags_tfl
  end
  
  #--------------------------------------------------------------------------
  # new method: load_notetags_tfl
  #--------------------------------------------------------------------------
  def self.load_notetags_tfl
    groups = [$data_actors]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_tfl
      end
    end
  end
  
end # DataManager

#==============================================================================
# ■ RPG::Actor
#==============================================================================

class RPG::Actor < RPG::BaseItem
  
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :face_layers
  attr_accessor :body_layers
  
  
  def face_base
    (@face_file == nil or @face_file.length <= 0) ? @face_name : @face_file
  end
  
  #--------------------------------------------------------------------------
  # load notetags
  #--------------------------------------------------------------------------
  def load_notetags_tfl
    #p "notes"
    @face_layers = []
    @face_layers_on = false
    @body_layers = []
    @body_layers_on = false
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TKK::ACTOR::FACE_BASE
        @face_file = $1.to_s
      #---
      when TKK::ACTOR::FACE_LAYERS_ON
        @face_layers_on = true
      when TKK::ACTOR::FACE_LAYERS_OFF
        @face_layers_on = false
      #---
      when TKK::ACTOR::BODY_LAYERS_ON
        @body_layers_on = true
      when TKK::ACTOR::BODY_LAYERS_OFF
        @body_layers_on = false
      #---
      else
        @face_layers.push(line.to_s) if @face_layers_on
        @body_layers.push(line.to_s) if @body_layers_on
      end
    } # self.note.split
    #---
    #for tflayer in @face_layers do
    #  p tflayer
    #end
    #for tflayer in @body_layers do
    #  p tflayer
    #end
  end
  
end # RPG::Actor

class Game_Actor < Game_Battler
  def face_layers
    return $data_actors[@actor_id].face_layers
  end
  def body_layers
    return $data_actors[@actor_id].body_layers
  end
end



#==============================================================================
# Windows
#==============================================================================

class Window_Base < Window
  
  
  alias window_base_draw_actor_face_tkk draw_actor_face
  def draw_actor_face(actor, x, y, enabled = true)
    datactor = $data_actors[actor.id]
    if datactor.face_layers.length > 0 then
      for tflayer in datactor.face_layers do
        unless tflayer.nil? or tflayer.length <= 0 or tflayer == "nil" then
          draw_face(datactor.face_base + tflayer, actor.face_index, x, y, enabled)
        end
      end
    else
      window_base_draw_actor_face_tkk(actor, x, y, enabled)
    end
  end
  
  
  
  alias window_base_draw_face_tkk draw_face
  def draw_face(face_name, face_index, x, y, enabled = true)
    if face_name == TKK::ACTOR::BUILD_FACE_ID then
      actor = $data_actors[face_index]
      for tflayer in actor.face_layers do
        unless tflayer.nil? or tflayer.length <= 0 or tflayer == "nil" then
          window_base_draw_face_tkk(actor.face_base + tflayer, actor.face_index, x, y, enabled)
        end
      end
    else
      window_base_draw_face_tkk(face_name, face_index, x, y, enabled)
    end
  end
  
  
  alias window_base_draw_actor_graphic_tkk draw_actor_graphic
  def draw_actor_graphic(actor, x, y)
    #p "fuk"
    datactor = $data_actors[actor.id]
    if datactor.body_layers.length > 0 then
      for tflayer in datactor.body_layers do
        unless tflayer.nil? or tflayer.length <= 0 or tflayer == "nil" then
          draw_character(actor.character_name + tflayer, actor.character_index, x, y)
        end
      end
    else
      window_base_draw_actor_graphic_tkk(actor, x, y)
    end
  end
  
end

class Window_Message < Window_Base
  
  alias window_message_change_face_tkk change_face
  def change_face(actor_id)
    actor_id = $game_party.members[actor_id.abs].id if actor_id <= 0
    actor = $data_actors[actor_id]
    return "" if actor.nil?
    if actor.face_layers.length > 0 then
      
      $game_message.face_name = TKK::ACTOR::BUILD_FACE_ID
      $game_message.face_index = actor_id
      return ""
    else
      window_message_change_face_tkk(actor_id)
    end
  end
  alias window_message_draw_face_tkk draw_face
  def draw_face(face_name, face_index, x, y, enabled = true)
    if face_name == TKK::ACTOR::BUILD_FACE_ID then
      actor = $data_actors[face_index]
      for tflayer in actor.face_layers do
        unless tflayer.nil? or tflayer.length <= 0 or tflayer == "nil" then
          window_message_draw_face_tkk(actor.face_base + tflayer, actor.face_index, x, y, enabled)
        end
      end
    else
      window_message_draw_face_tkk(face_name, face_index, x, y, enabled)
    end
  end
end

class Window_BattleStatus < Window_Selectable
  
  alias window_battlestatus_draw_face_tkk draw_face
  def draw_face(face_name, face_index, x, y, enabled = true)
    if face_name == TKK::ACTOR::BUILD_FACE_ID then
      actor = $data_actors[face_index]
      for tflayer in actor.face_layers do
        unless tflayer.nil? or tflayer.length <= 0 or tflayer == "nil" then
          window_battlestatus_draw_face_tkk(actor.face_base + tflayer, actor.face_index, x, y, enabled)
        end
      end
    else
      window_battlestatus_draw_face_tkk(face_name, face_index, x, y, enabled)
    end
  end
  
  alias window_battlestatus_draw_actor_face_tkk draw_actor_face
  def draw_actor_face(actor, x, y, enabled = true)
    if (actor.face_layers != nil && actor.face_layers.length > 0) then
      dummy_id = get_kinu_dummy_id(actor)
      datactor = $data_actors[dummy_id]
      for tflayer in datactor.face_layers do
        unless tflayer.nil? or tflayer.length <= 0 or tflayer == "nil" then
          #p tflayer
          draw_face(datactor.face_base + tflayer, datactor.face_index, x, y, enabled)
        end
      end
    else
      window_battlestatus_draw_actor_face_tkk(actor, x, y, enabled)
    end
  end
  
  
  def get_kinu_dummy_id(actor)
    if KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id] != nil
      # If array at start has faces configured for this actor, use the so called "dummy acors"
      # Finds the dummy actor number matching the various situations.
      # The numbers themselves are defined in a module at the start.
      
      # Show dead face.
      dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][3]
      return dummy_actor_id if actor.alive? == false && dummy_actor_id != nil && dummy_actor_id != -1
      
      # Show highest priority condition/state face.
      for i in 0 ... KINU::BATTLE_UI_TWEAK::STATES.size
        dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][i+KINU::BATTLE_UI_TWEAK::NUMBER_OF_FACES_BEFORE_STATES]
        return dummy_actor_id if actor.kinu_check_state(i) == true && dummy_actor_id != nil && dummy_actor_id != -1
      end
      
      # Show low hp face.
      dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][2]
      return dummy_actor_id if actor.hp.to_f / actor.mhp < KINU::BATTLE_UI_TWEAK::LOW_HP_THRESHOLD && dummy_actor_id != nil && dummy_actor_id != -1
      
      # Show high hp face.
      dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][0]
      return dummy_actor_id if actor.hp.to_f / actor.mhp > KINU::BATTLE_UI_TWEAK::HIGH_HP_THRESHOLD && dummy_actor_id != nil && dummy_actor_id != -1
      
      # Show medium/default face.
      dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][1]
      return dummy_actor_id if dummy_actor_id != nil && dummy_actor_id != -1
      
      # This should in theory never be reached, but it is here to prevent an error.
      return actor.actor_id
    else
      # Just use regular face otherwise.
      return actor.actor_id
    end
  end
    
end


class Window_BattleStatusAid < Window_BattleStatus
  alias window_battlestatusaid_draw_face_tkk draw_face
  def draw_face(face_name, face_index, x, y, enabled = true)
    if face_name == TKK::ACTOR::BUILD_FACE_ID then
      actor = $data_actors[face_index]
      for tflayer in actor.face_layers do
        unless tflayer.nil? or tflayer.length <= 0 or tflayer == "nil" then
          window_battlestatusaid_draw_face_tkk(actor.face_base + tflayer, actor.face_index, x, y, enabled)
        end
      end
    else
      window_battlestatusaid_draw_face_tkk(face_name, face_index, x, y, enabled)
    end
  end
  
  alias window_battlestatusaid_draw_actor_face_tkk draw_actor_face
  def draw_actor_face(actor, x, y, enabled = true)
    if (actor.face_layers != nil && actor.face_layers.length > 0) then
      dummy_id = get_kinu_dummy_id(actor)
      # First we need to know what face, so get the name and index
      face_name = TKK::ACTOR::BUILD_FACE_ID
      face_index = dummy_id
      # Now draw the face :P
      draw_face(face_name, face_index, x, y, enabled)
    else
      window_battlestatusaid_draw_actor_face_tkk(actor, x, y, enabled)
    end
  end
  
  
  def get_kinu_dummy_id(actor)
    if KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id] != nil
      # If array at start has faces configured for this actor, use the so called "dummy acors"
      # Finds the dummy actor number matching the various situations.
      # The numbers themselves are defined in a module at the start.
      
      # Show mono face when attacking.
      dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][4]
      return dummy_actor_id if dummy_actor_id != nil && dummy_actor_id != -1
      
      # Show dead face.
      dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][3]
      return dummy_actor_id if actor.alive? == false && dummy_actor_id != nil && dummy_actor_id != -1
      
      # Show highest priority condition/state face.
      for i in 0 ... KINU::BATTLE_UI_TWEAK::STATES.size
        dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][i+KINU::BATTLE_UI_TWEAK::NUMBER_OF_FACES_BEFORE_STATES]
        return dummy_actor_id if actor.kinu_check_state(i) == true && dummy_actor_id != nil && dummy_actor_id != -1
      end
      
      # Show low hp face.
      dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][2]
      return dummy_actor_id if actor.hp.to_f / actor.mhp < KINU::BATTLE_UI_TWEAK::LOW_HP_THRESHOLD && dummy_actor_id != nil && dummy_actor_id != -1
      
      # Show high hp face.
      dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][0]
      return dummy_actor_id if actor.hp.to_f / actor.mhp > KINU::BATTLE_UI_TWEAK::HIGH_HP_THRESHOLD && dummy_actor_id != nil && dummy_actor_id != -1
      
      # Show medium/default face.
      dummy_actor_id = KINU::BATTLE_UI_TWEAK::FACES[actor.actor_id][1]
      return dummy_actor_id if dummy_actor_id != nil && dummy_actor_id != -1
      
      # This should in theory never be reached, but it is here to prevent an error.
      return actor.actor_id
    else
      # Just use regular face otherwise.
      return actor.actor_id
    end
  end
end





  #--------------------------------------------------------------------------
  # * Levi Stepp's Enhanced Save extension
  #--------------------------------------------------------------------------
class Game_Party < Game_Unit

  def faces_for_savefile
    battle_members.collect do |actor|
      [actor.face_name, actor.face_index, actor.face_layers]
    end
  end
end

class Window_SaveFile < Window_Base
  def draw_party_faces(x, y)
    header = DataManager.load_header(@file_index)
    return unless header && header[:faces]
    header[:faces].each_with_index do |data, i|
      draw_face(data[0], data[1], x + i * 108, y)
      if data[2] != nil && data[2].length > 0 then
        data[2].each do |tflayer|
          draw_face(data[0] + tflayer, data[1], x + i * 108, y) if tflayer != nil && tflayer.length > 0 && tflayer != "nil"
        end
      end
    end
  end
end


















  #--------------------------------------------------------------------------
  # * Character Graphics
  #--------------------------------------------------------------------------

class Game_CharacterBase
  # Accessors. lots of them. don't question me.
  def x=(inp)
    @x = inp
  end
  def y=(inp)
    @y = inp
  end
  def real_x=(inp)
    @real_x = inp
  end
  def real_y=(inp)
    @real_y = inp
  end
  def tile_id=(inp)
    @tile_id = inp
  end
  def character_name=(inp)
    @character_name = inp
  end
  def character_index=(inp)
    @character_index = inp
  end
  def move_speed=(inp)
    @move_speed = inp
  end
  def move_frequency=(inp)
    @move_frequency = inp
  end
  def walk_anime=(inp)
    @walk_anime = inp
  end
  def step_anime=(inp)
    @step_anime = inp
  end
  def direction_fix=(inp)
    @direction_fix = inp
  end
  def opacity=(inp)
    @opacity = inp
  end
  def blend_type=(inp)
    @blend_type = inp
  end
  def direction=(inp)
    @direction = inp
  end
  def pattern=(inp)
    @pattern = inp
  end
  def priority_type=(inp)
    @priority_type
  end
  def through=(inp)
    @through = inp
  end
  def bush_depth=(inp)
    @bush_depth = inp
  end
end



class Game_Player
  alias game_player_update_tkk update
  def update
    game_player_update_tkk
    
    
    if actor then
      datactor = $data_actors[actor.id]
      if datactor.body_layers.length > 0 then
        for tflayer in datactor.body_layers do
          unless tflayer.nil? or tflayer.length <= 0 or tflayer == "nil" then
            draw_character_tkk(actor.character_name + tflayer, character_index, x, y)
          end
        end
      end
    end
  end
  
  
  
  def draw_character_tkk(character_name, character_index, x, y)
    return unless character_name
    bitmap = Cache.character(character_name)
    sign = character_name[/^[\!\$]./]
    if sign && sign.include?('$')
      cw = bitmap.width / 3
      ch = bitmap.height / 4
    else
      cw = bitmap.width / 12
      ch = bitmap.height / 8
    end
    n = character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, cw, ch)
    #contents.blt(x - cw / 2, y - ch, bitmap, src_rect)
  end
end




class Spriteset_Map
  
  attr_accessor :player_layers
  
  alias spriteset_map_create_characters_tkk create_characters
  def create_characters
    spriteset_map_create_characters_tkk
    @player_layers = []
    
    for tflayer in $data_actors[$game_player.actor.id].body_layers do
      #p "spriteset found body layer!"
      @player_layers.push(Sprite_Character.new(@viewport1, Game_Character.new))
    end
    
  end
  
  
  alias spriteset_map_dispose_characters_tkk dispose_characters
  def dispose_characters
    spriteset_map_dispose_characters_tkk
    @player_layers.each {|sprite| sprite.dispose }
  end
  
  alias spriteset_map_update_characters_tkk update_characters
  def update_characters
    spriteset_map_update_characters_tkk
    cnter = 0
    layerz = $data_actors[$game_player.actor.id].body_layers
    while cnter < @player_layers.length do
      cnter = cnter + 1
      next if layerz[cnter] == nil or $game_player == nil or @player_layers[cnter] == nil
      #@player_layers[cnter].character.x = $game_player.id
      @player_layers[cnter].character.x = $game_player.x
      @player_layers[cnter].character.y = $game_player.y
      @player_layers[cnter].character.real_x = $game_player.real_x
      @player_layers[cnter].character.real_y = $game_player.real_y
      @player_layers[cnter].character.tile_id = $game_player.tile_id
      @player_layers[cnter].character.character_name = $game_player.character_name + layerz[cnter] unless layerz[cnter] == "nil"
      @player_layers[cnter].character.character_index = $game_player.character_index
      @player_layers[cnter].character.move_speed = $game_player.move_speed
      @player_layers[cnter].character.move_frequency = $game_player.move_frequency
      @player_layers[cnter].character.walk_anime = $game_player.walk_anime
      @player_layers[cnter].character.step_anime = $game_player.step_anime
      @player_layers[cnter].character.direction_fix = $game_player.direction_fix
      @player_layers[cnter].character.opacity = $game_player.opacity unless layerz[cnter] == "nil"
      @player_layers[cnter].character.blend_type = $game_player.blend_type
      @player_layers[cnter].character.direction = $game_player.direction
      @player_layers[cnter].character.pattern = $game_player.pattern
      @player_layers[cnter].character.priority_type = $game_player.priority_type
      @player_layers[cnter].character.through = $game_player.through
      @player_layers[cnter].character.bush_depth = $game_player.bush_depth
      @player_layers[cnter].character.animation_id = $game_player.animation_id
      @player_layers[cnter].character.balloon_id = $game_player.balloon_id
      @player_layers[cnter].character.transparent = $game_player.transparent
      @player_layers[cnter].character.opacity = 0 if layerz[cnter] == "nil"
      @player_layers[cnter].update
    end
  end
end
