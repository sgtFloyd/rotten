class Numeric
  KILOBYTE = 1024
  MEGABYTE = KILOBYTE * 1024
  GIGABYTE = MEGABYTE * 1024
  TERABYTE = GIGABYTE * 1024
  PETABYTE = TERABYTE * 1024
  EXABYTE  = PETABYTE * 1024

  def bytes; self; end
  alias :byte :bytes

  def kilobytes; self * KILOBYTE; end
  alias :kilobyte :kilobytes

  def megabytes; self * MEGABYTE; end
  alias :megabyte :megabytes

  def gigabytes; self * GIGABYTE; end
  alias :gigabyte :gigabytes

  def terabytes; self * TERABYTE; end
  alias :terabyte :terabytes

  def petabytes; self * PETABYTE; end
  alias :petabyte :petabytes

  def exabytes; self * EXABYTE; end
  alias :exabyte :exabytes
end

class String
  BYTE_UNITS = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB']
  BYTE_REGEX = /[.\d]+\s?(?<unit>#{BYTE_UNITS.join('|')})/

  def to_bytes
    if match = self.match(BYTE_REGEX)
      self.to_f * (1024 ** BYTE_UNITS.index(match[:unit]))
    end
  end
end
