#!/usr/bin/env ruby
#
# check_glusterfs - 	plugin fpr nagios to check glusterfs quota usage. In later realeases 
# 			you can check other stuff like performance
#
# Author: 	Heiko Krämer (kraemer@avarteq.de)
# Date:		2012-09-21
#
## This program is free software; you can redistribute it and/or modify
#
## it under the terms of the GNU General Public License as published by
#
## the Free Software Foundation; either version 2 of the License, or
#
## (at your option) any later version.
#
##
#
## This program is distributed in the hope that it will be useful,
#
## but WITHOUT ANY WARRANTY; without even the implied warranty of
#
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#
## GNU Library General Public License for more details.
#
##
#
## You should have received a copy of the GNU General Public License
#
## along with this program; if not, write to the Free Software
#
## Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#


#
######################
###### Usage  ########
######################
# ./check_glusterfs.rb -n <volume-name> -c 20 -w 10
#

require 'optparse'


@VOLUME_NAME=""
@CRITCAL=0
@WARNING=0
@usage={}
@threshold={}

# Parsing all arguments
opts = OptionParser.new do |opts|

  opts.banner = "Usage: check_glusterfs.rb -c <critical-percentage> -w <warning-percentage> -n <volume-name>  "


  opts.on("-c","--critcal [CRIT]", "Percentage of the maximum space") do |crit|
	@CRITICAL=crit
  end

  opts.on("-w","--warning [WARN]", "Percentage of the maximum space") do |warn|
        @WARNING=warn
  end

  opts.on("-n","--volume-name [NAME]") do |name|
        @VOLUME_NAME=name
  end

end	
opts.parse!(ARGV)

def calculate_size(size)
	if size.match(/MB/)
  	return size.gsub("MB","").to_f / 1024
  else
  	return size.gsub("GB","").to_f
  end
end


# Parsing output of gluster command
def parse_output(output)
  usage={}
  tmp= output.split("\n")[2].split(" ")
  @usage["path"] = tmp[0]
  @usage["limit_set"] = claculate_size(tmp[1])
  @usage["used"] = calculate_size(tmp[2])
  @usage["free"] = @usage["limit_set"] - @usage["used"]
end

def get_volume_quota_usage(vol_name)
  command = "sudo gluster volume quota #{vol_name} list"
  parse_output(`#{command}`)
end

def calulate_threshold
  @threshold["warning"] = @usage["limit_set"] / 100.0 * @WARNING.to_f
  @threshold["critical"] = @usage["limit_set"] / 100.0 * @CRITICAL.to_f
end




get_volume_quota_usage(@VOLUME_NAME)
calulate_threshold

# Check if it's a warning state or critical
unless @usage["free"] >= @threshold["critical"]
  puts "Volume #{@VOLUME_NAME} has #{@usage["free"].round(2)}GB free of #{@usage["limit_set"]}GB maximum space"
  exit(2)
end


unless @usage["free"] >= @threshold["warning"]
  puts "Volume #{@VOLUME_NAME} has #{@usage["free"].round(2)}GB free of #{@usage["limit_set"]}GB maximum space"
  exit(1)
end


puts "Volume #{@VOLUME_NAME} has #{@usage["free"].round(2)}GB free of #{@usage["limit_set"]}GB maximum space"

exit(0)

