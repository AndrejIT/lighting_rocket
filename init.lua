
lighting_rocket = {}
lighting_rocket.speed = 8
lighting_rocket.acceleration = {x = 0, y = -0.75, z = 0}
lighting_rocket.time = 15
lighting_rocket.light_time = 120
lighting_rocket.light_radius = 10

-- animation of rocket flying
lighting_rocket.launch = function(pos, dir)
    local vel = vector.multiply(dir, lighting_rocket.speed)
    minetest.add_particlespawner({
        amount = 10,
        time = 0.01,
        minpos = pos,
        maxpos = pos,
        minvel = vel,
        maxvel = vel,
        minacc = lighting_rocket.acceleration,
        maxacc = lighting_rocket.acceleration,
        minexptime = lighting_rocket.time*0.5,
        maxexptime = lighting_rocket.time,
        minsize = 5,
        maxsize = 8,
        collisiondetection = false,
        glow = 14,
        texture = "tnt_smoke.png",
    })
end

-- actual light placement across the rocket path
lighting_rocket.launch_light = function(pos, vel, remaining_time)
    local new_pos = vector.add(
        vector.add(pos, vel),
        vector.multiply(lighting_rocket.acceleration, 0.5)
    )
    local new_vel = vector.add(vel, lighting_rocket.acceleration)
    local new_remaining_time = remaining_time - 1

    if not lighting_rocket.add_light(new_pos) then
        return
    end

    if new_remaining_time > 0 then
        minetest.after(1, lighting_rocket.launch_light, new_pos, new_vel, new_remaining_time)
    end
end

-- add light around pos.
lighting_rocket.add_light = function(pos)
    if minetest.get_node(pos).name ~= "air" then
        return false
    end

    -- just approximately...
    local lights_count = 1 + math.floor(math.pow(lighting_rocket.light_radius/5, 3))

    for i=1, lights_count, 1 do
        local area_pos = {
            x=pos.x + math.random(-lighting_rocket.light_radius, lighting_rocket.light_radius),
            y=pos.y + math.random(-lighting_rocket.light_radius, lighting_rocket.light_radius),
            z=pos.z + math.random(-lighting_rocket.light_radius, lighting_rocket.light_radius)
        }

        if minetest.get_node(area_pos).name == "air" then
            minetest.set_node(area_pos, {name="lighting_rocket:light_air"})
        end
    end

    -- additionaly light area under
    local under_pos = {x=pos.x,y=pos.y-lighting_rocket.light_radius,z=pos.z}
    if minetest.get_node(under_pos).name == "air" then
        for i=1, lights_count, 1 do
            local area_pos = {
                x=under_pos.x + math.random(-lighting_rocket.light_radius, lighting_rocket.light_radius),
                y=under_pos.y + math.random(-lighting_rocket.light_radius, lighting_rocket.light_radius),
                z=under_pos.z + math.random(-lighting_rocket.light_radius, lighting_rocket.light_radius)
            }

            if minetest.get_node(area_pos).name == "air" then
                minetest.set_node(area_pos, {name="lighting_rocket:light_air"})
            end
        end
    end

    return true
end

minetest.register_craftitem("lighting_rocket:rocket", {
	description = "Lighting rocket (flare)",
    inventory_image = "lighting_rocket.png",
	wield_image = "lighting_rocket.png",
    on_use = function(itemstack, player, pointed_thing)
        local pos = player:get_pos()
        pos.y = pos.y + 1
        local dir = player:get_look_dir()

        lighting_rocket.launch(pos, dir)
        lighting_rocket.launch_light(pos, vector.multiply(dir, lighting_rocket.speed), lighting_rocket.time)
        minetest.sound_play("tnt_ignite", {pos=pos})

        itemstack:take_item(1)

        return itemstack
    end,
})

minetest.register_node("lighting_rocket:light_air", {
	drawtype = "airlike",
	walkable = false,
	pointable = false,
	diggable = false,
	climbable = false,
	buildable_to = true,
	drop = {},
	sunlight_propagates = true,
	paramtype = "light",
	light_source = 14,
    groups = {not_in_creative_inventory = 1},

    on_timer = function(pos, elapsed)
        minetest.set_node(pos, {name="air"})
        return false    -- prevent futher execution?
    end,
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(lighting_rocket.light_time)
    end,
})

minetest.register_craft({
	output = "lighting_rocket:rocket 4",
	recipe = {
		{"", "default:coal_lump", ""},
		{"default:coal_lump", "default:torch", "default:coal_lump"},
		{"", "tnt:gunpowder", ""}
	},
})
