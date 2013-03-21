require 'PageElement'

class Action < PageElement
  attr_accessor :params

  def initialize label, params
    super label
    @params = params
  end

  def to_snippet
    if @params
      return "\taction #{@label.inspect} do |#{params.join(", ")}|\n\tend\n\n"
    else
      return "\taction #{@label.inspect} do\n\tend\n\n"
    end
  end
end