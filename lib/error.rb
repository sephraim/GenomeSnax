# A class of various error methods
#
# @author Sean Ephraim
class Error
  # Throws a fatal error and exits
  #
  # @param msg [String] Error message
  def self.fatal(msg)
    abort "ERROR: #{msg}"
  end
end
