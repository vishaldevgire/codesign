class ConsoleLogger
  def self.info message
    puts "\e[1;34m[INFO]\e[0m #{message}"
  end

  def self.warn message
    puts "\e[1;33m[WARN]\e[0m #{message}"
  end

  def self.error message
    puts "\e[1;31m[ERROR]\e[0m #{message}"
  end
end