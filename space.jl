
mkpath("space/me/default")
mkpath("space/follow")
mkpath("space/public")

if !isfile("space/me/default/get.txt") open("space/me/get.txt", "w") do file write(file, "*:[*]\n") end end
if !isfile("space/me/default/put.txt") open("space/me/put.txt", "w") do file write(file, "*:[]\n") end end
if !isfile("space/me/default/set.txt") open("space/me/set.txt", "w") do file write(file, "*:[]\n") end end

#


# dir structure; space/
#   names.txt 					=> your shortcut names to user_ids
# 	me
# 		/myplace
# 			get.txt
# 			put.txt
# 			set.txt
# 			changes.txt 		=> keeps a list of updated hashindices (each one created 1 time, updated N times, table)
# 			followers.txt		=> which follower keeps which prefixes, andlast time they synced (the files and get.txt)
# 			/content
# 				hashid.ext
#	otherid
#		/otherspace
#			get.txt
# 			check.txt			=> last sync times for get and content
#			/content
#				hashid.ext
#	public
#		hashid.ext


#

function find_in_space(path::String)
	if !path=="public" path*="/content" end
	files = readdir("space/$(path)")
	idx = find(e -> startswith(e, msg["id"]), files)
	if idx!=nothing return files[idx] end
	return nothing
end


function rule_in_space(prefix::String, id_req::String; id_res::String, mode::String) # get, put, set
	if id_res==Nothing # its me/content

	else # its follow/id_res/content

	end
end


function follower_in_space(path::String)
	# return a list of followers that have that specific path
	#
	# /space/me/myspace/followers.txt

end
