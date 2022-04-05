#
#TKK::CHOICEIN::makeWordNumbers( [ ["Lorium", "Ipsum"], ["Example", "Text"] ])

#==============================================================================
# 
# ▼ Input Word Numbers
# -- Last Updated: 2022.03.28
# -- Creator: The_Evil_Pickle
# -- Requires: n/a
# 
#==============================================================================
# Description:
# This script lets you ask the player to choose between several combinations of words using the "Number Input..." event command
#
#==============================================================================
# Instructions: Put this in Materials
# 
# To activate, call the following script right before opening number input (without "#" symbol) 
#TKK::CHOICEIN::makeWordNumbers( [[]] )
# The input for the function must be an array of arrays of strings.
#
# For example, 
# TKK::CHOICEIN::makeWordNumbers( [ ["Lorium", "Ipsum"], ["Example", "Text"] ] )
# will give the player the options "Lorium Example", "Lorium Text", "Ipsum Example", and "Ipsum Text"
# The value saved to the variable in this example will be 0, 1, 10, or 11 respectively.
# 
# If you ask the player for number input without calling this script first, a normal number input window will appear.
#==============================================================================




module TKK
  module CHOICEIN
    
    
    @@isThisWordsNumbers = false
    @@wordNumberOptions = [
      ["UNDEFINED", "DEFAULT"],
      ["WORDS", "INPUTS"]
    ]
    @@wordNumberSpacing = 120
    
    def self.isThisWordsNumbers
      @@isThisWordsNumbers
    end
    def self.makeWordNumbers(inp)
      @@isThisWordsNumbers = true
      @@wordNumberOptions = inp
    end
    def self.endWordNumbers
      @@isThisWordsNumbers = false
    end
    def self.wordNumberOptions
      @@wordNumberOptions
    end
    def self.wordNumberSpacing
      @@wordNumberSpacing
    end
  end # CHOICEIN
end # TKK

#==============================================================================
# ** Window_NumberInput
#------------------------------------------------------------------------------
#  This window is used for the event command [Input Number].
#==============================================================================

class Window_NumberInput < Window_Base
  
  #--------------------------------------------------------------------------
  # * Update Window Position
  #--------------------------------------------------------------------------
  alias window_numberinput_update_placement_tkksc update_placement
  def update_placement
    if (TKK::CHOICEIN::isThisWordsNumbers) then
      self.width = @digits_max * TKK::CHOICEIN::wordNumberSpacing + padding * 2
      self.height = fitting_height(1)
      self.x = (Graphics.width - width) / 2
      if @message_window.y >= Graphics.height / 2
        self.y = @message_window.y - height - 8
      else
        self.y = @message_window.y + @message_window.height + 8
      end
    else
      window_numberinput_update_placement_tkksc
    end
    
    
  end
  
  #--------------------------------------------------------------------------
  # * Change Processing for Digits
  #--------------------------------------------------------------------------
  alias window_numberinput_process_digit_change_tkksc process_digit_change
  def process_digit_change
    return unless active
    if (TKK::CHOICEIN::isThisWordsNumbers) then
      if Input.repeat?(:UP) || Input.repeat?(:DOWN)
        Sound.play_cursor
        place = 10 ** (@digits_max - 1 - @index)
        n = @number / place % 10
        @number -= n * place
        n = (n + 1) % (TKK::CHOICEIN::wordNumberOptions[@index].length()) if Input.repeat?(:UP)
        n = (n + TKK::CHOICEIN::wordNumberOptions[@index].length() - 1) % (TKK::CHOICEIN::wordNumberOptions[@index].length()) if Input.repeat?(:DOWN)
        @number += n * place
        refresh
      end
    else
      window_numberinput_process_digit_change_tkksc
    end
  end
  
  #--------------------------------------------------------------------------
  # * Get Rectangle for Displaying Item
  #--------------------------------------------------------------------------
  alias window_numberinput_item_rect_tkksc item_rect
  def item_rect(index)
    if (TKK::CHOICEIN::isThisWordsNumbers) then
      return Rect.new(index * TKK::CHOICEIN::wordNumberSpacing, 0, TKK::CHOICEIN::wordNumberSpacing, line_height)
    else
      return window_numberinput_item_rect_tkksc(index)
    end
  end
  
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  alias window_numberinput_refresh_tkksc refresh
  def refresh
    if (TKK::CHOICEIN::isThisWordsNumbers) then
      contents.clear
      change_color(normal_color)
      s = sprintf("%0*d", @digits_max, @number)
      @digits_max.times do |i|
        rect = item_rect(i)
        rect.x += 1
        draw_text(rect, TKK::CHOICEIN::wordNumberOptions[i][@number / (10 ** (@digits_max - 1 - i)) % 10], 1)
      end
    else
      window_numberinput_refresh_tkksc
    end
  end
  
  #--------------------------------------------------------------------------
  # * Processing When OK Button Is Pressed
  #--------------------------------------------------------------------------
  alias window_numberinput_process_ok_tkksc process_ok
  def process_ok
    TKK::CHOICEIN::endWordNumbers
    window_numberinput_process_ok_tkksc
  end
  #--------------------------------------------------------------------------
  # * Processing When Cancel Button Is Pressed
  #--------------------------------------------------------------------------
  alias window_numberinput_process_cancel_tkksc process_cancel
  def process_cancel
    TKK::CHOICEIN::endWordNumbers
    window_numberinput_process_cancel_tkksc
  end
end
