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

  # Throws a warning error but doesn't exit
  #
  # @param msg [String] Error message
  def self.warning(msg)
    abort "WARNING: #{msg}"
  end
end
