#!/usr/bin/env ruby

require "fileutils"
require "pathname"
require "shellwords"
require "time"
include FileUtils::Verbose

class Pathname
  alias_method :/, :+ unless method_defined?(:/)
  alias_method :to_str, :to_s unless method_defined?(:to_str)
end

def system(*args)
  puts args.shelljoin
  super
end

def lock(path)
  file = Pathname.new(path).open(File::RDWR | File::CREAT)
  unless file.flock(File::LOCK_EX | File::LOCK_NB)
    raise "Failed to lock #{path}"
  end
end

MC_PATH = Pathname.new "/opt/minecraft/server/"
BAK_PATH = Pathname.new "/opt/minecraft/backup"
STAGE_PATH = BAK_PATH/"stage"
AR_PATH = BAK_PATH/"archives"

lock "/tmp/mc-backup.lock"

mkdir_p STAGE_PATH
mkdir_p AR_PATH

system "rsync", "-avcr", "--exclude", "logs", MC_PATH, STAGE_PATH
cd(STAGE_PATH) do
  system "tar", "-czvf", AR_PATH/"#{Time.now.iso8601}.tar.gz", "."
end
system "find", AR_PATH, "-mtime", "+3", "-type", "f", "-print", "-delete"

