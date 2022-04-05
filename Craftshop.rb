

#==============================================================================
# 
# ▼ Craftshop
# -- Last Updated: 2022.01.13
# -- Creator: The_Evil_Pickle
# -- Requires: n/a
# 
# Instructions: Put this in Materials
# To open a craftshop, call the following script right before shop processing (without "#" symbol):
#TKK::CRAFTSHOP::makeCraftShop
#==============================================================================
# -----------------------------------------------------------------------------
# Item Notetags - These notetags go in the item, armor, or equipment notebox in the database.
# -----------------------------------------------------------------------------
# 
# <craftshop recipe: x>
# <craftshop recipe: x, x>
# Items with the listed IDs will be required to purchase this item from a craftshop.
# If the same ID is listed multiple times, multiple copies of that item are required.
# 
# <craftshop armor: x>
# <craftshop armor: x, x>
# Same as above, but requires the armor with the specified ID(s) instead of the item.
#
# <craftshop weapon: x>
# <craftshop weapon: x, x>
# Same as above, but requires the weapon with the specified ID(s) instead of the item.
# 






module TKK
  module CRAFTSHOP
    
    
    @@inCraftShop = false
    @@setupToggle = false
    
    def self.isThisCraftShop
      @@inCraftShop
    end
    def self.setupToggle
      @@setupToggle
    end
    def self.doToggle
      @@setupToggle = true
    end
    def self.makeCraftShop
      @@inCraftShop = true
      @@setupToggle = false
    end
    def self.endCraftShop
      @@inCraftShop = false
      @@setupToggle = false
    end
  end # CHOICEIN
  module ITEMREG
    CRAFTSHOP_INGREDIENTS  = /<(?:CRAFTSHOP_RECIPE|craftshop recipe):[ ]*(\d+(?:\s*,\s*\d+)*)>/i
    CRAFTSHOP_ARMOR  = /<(?:CRAFTSHOP_ARMOR|craftshop armor):[ ]*(\d+(?:\s*,\s*\d+)*)>/i
    CRAFTSHOP_WEAPON  = /<(?:CRAFTSHOP_WEAPON|craftshop weapon):[ ]*(\d+(?:\s*,\s*\d+)*)>/i
  end # ITEMREG
end # TKK




#==============================================================================
# ■ DataManager
#==============================================================================

module DataManager
  
  #--------------------------------------------------------------------------
  # alias method: load_database
  #--------------------------------------------------------------------------
  class <<self; alias load_database_tkkcs load_database; end
  def self.load_database
    load_database_tkkcs
    load_notetags_tkkcs
  end
  
  #--------------------------------------------------------------------------
  # new method: load_notetags_tkkcs
  #--------------------------------------------------------------------------
  def self.load_notetags_tkkcs
    groups = [$data_items, $data_armors, $data_weapons]
    for group in groups
      for obj in group
        next if obj.nil?
        obj.load_notetags_tkkcs
      end
    end
  end
  
end # DataManager


#==============================================================================
# ■ RPG::BaseItem
#==============================================================================

class RPG::BaseItem
  
  #--------------------------------------------------------------------------
  # public instance variables
  #--------------------------------------------------------------------------
  attr_accessor :tkkcs_recipe
  
  #--------------------------------------------------------------------------
  # common cache: load_notetags_pst
  #--------------------------------------------------------------------------
  def load_notetags_tkkcs
    @tkkcs_recipe = []
    quickcounter = []
    quickcounter_armor = []
    quickcounter_weapon = []
    while quickcounter.length <= $data_items.length do
      quickcounter.push(0)
    end
    while quickcounter_armor.length <= $data_armors.length do
      quickcounter_armor.push(0)
    end
    while quickcounter_weapon.length <= $data_weapons.length do
      quickcounter_weapon.push(0)
    end
    #---
    self.note.split(/[\r\n]+/).each { |line|
      case line
      #---
      when TKK::ITEMREG::CRAFTSHOP_INGREDIENTS
        $1.scan(/\d+/).each { |num| 
        quickcounter[num.to_i] += 1 if num.to_i > 0 }
      #---
      when TKK::ITEMREG::CRAFTSHOP_ARMOR
        $1.scan(/\d+/).each { |num| 
        quickcounter_armor[num.to_i] += 1 if num.to_i > 0 }
      #---
      when TKK::ITEMREG::CRAFTSHOP_WEAPON
        $1.scan(/\d+/).each { |num| 
        quickcounter_weapon[num.to_i] += 1 if num.to_i > 0 }
      #---
      end
    } # self.note.split
    cnter = 1;
    while cnter < quickcounter.length do
      if quickcounter[cnter] > 0 then
        @tkkcs_recipe.push([$data_items[cnter], quickcounter[cnter]])
      end
      cnter += 1;
    end
    cnter = 1;
    while cnter < quickcounter_armor.length do
      if quickcounter_armor[cnter] > 0 then
        @tkkcs_recipe.push([$data_armors[cnter], quickcounter_armor[cnter]])
      end
      cnter += 1;
    end
    cnter = 1;
    while cnter < quickcounter_weapon.length do
      if quickcounter_weapon[cnter] > 0 then
        @tkkcs_recipe.push([$data_weapons[cnter], quickcounter_weapon[cnter]])
      end
      cnter += 1;
    end
    #---
  end
  
end # RPG::BaseItem


#==============================================================================
# ■ Window_ShopBuy
#==============================================================================

class Window_ShopBuy < Window_Selectable
  
  
  alias window_shopbuy_enable_tkkcs enable?
  def enable?(item)
    if (TKK::CRAFTSHOP::isThisCraftShop) then
      return false unless window_shopbuy_enable_tkkcs(item)
      item.tkkcs_recipe.each { |ingredient|
      return false if $game_party.item_number(ingredient[0]) < ingredient[1] }
      return true;
    else
      return window_shopbuy_enable_tkkcs(item)
    end
  end
  
end




#==============================================================================
# ■ Window_ShopStatus
#==============================================================================

class Window_ShopStatus < Window_Base
  
  alias window_shopstatus_draw_equip_info_tkkcs draw_equip_info
  def draw_equip_info(x, y)
    if (TKK::CRAFTSHOP::isThisCraftShop) then
      linum = 0
      @item.tkkcs_recipe.each { |ingredient|
      enabled = $game_party.item_number(ingredient[0]) >= ingredient[1]
      change_color(normal_color, enabled)
      draw_text(x, y + linum * line_height, 224, line_height, ingredient[0].name + " " + $game_party.item_number(ingredient[0]).to_s + "/" + ingredient[1].to_s)
      linum += 1
      }
    else
      window_shopstatus_draw_equip_info_tkkcs(x, y)
    end
  end
  
end


#==============================================================================
# ■ Window_ShopCommand
#==============================================================================

class Window_ShopCommand < Window_HorzCommand
  #--------------------------------------------------------------------------
  # ● Init
  #--------------------------------------------------------------------------
  alias window_shopcommand_init_tkkcs initialize
  def initialize(window_width, purchase_only)
    p "init shop command"
    if (TKK::CRAFTSHOP::isThisCraftShop) then
      if (TKK::CRAFTSHOP::setupToggle) then
        TKK::CRAFTSHOP::endCraftShop
      else
        TKK::CRAFTSHOP::doToggle
      end
    end
    window_shopcommand_init_tkkcs(window_width, purchase_only)
  end
end
