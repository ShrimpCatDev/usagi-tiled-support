local map={}

function map:init(path)
    local m=require(path)
    m.time=0
    m.sw=usagi.GAME_W
    m.sh=usagi.GAME_H
    m.animLookup={}
    m.collidableTiles={}
    m.layersByName={}
    m.tileProperties={}
    for b,tileset in ipairs(m.tilesets) do
        for c,tile in ipairs(tileset.tiles) do
            if tile.animation then
                tile.time=0
                tile.frame=1
                m.animLookup[tile.id+1]=tile
            end
            if tile.properties and tile.properties.collidable then
                m.collidableTiles[tile.id+1]=tile.properties
            end
            if tile.properties then
                m.tileProperties[tile.id+1]=tile.properties
            end
        end
    end
    for k,layer in ipairs(m.layers) do
        m.layersByName[layer.name]=layer
    end
    m.drawlayer=function(mself,layername,dx,dy)
        local layer=m.layersByName[layername]
        if layer and layer.visible then
                local ox=math.floor(((dx or 0)+(layer.offsetx))*layer.parallaxx)
                local oy=math.floor(((dy or 0)+(layer.offsety))*layer.parallaxy)
                if layer.type=="tilelayer" then
                    local minX = math.max(0, math.floor(-ox / mself.tilewidth))
                    local maxX = math.min(layer.width-1, math.ceil((mself.sw-ox)/mself.tilewidth))
                    local minY = math.max(0, math.floor(-oy / mself.tileheight))
                    local maxY = math.min(layer.height-1, math.ceil((mself.sh-oy)/mself.tileheight))
                    
                    for y = minY,maxY do
                        for x = minX,maxX do
                            local index = y * layer.width + x + 1
                            local tileId = layer.data[index]
                            if tileId ~= 0 then
                                local animTile = m.animLookup[tileId]
                                if animTile then
                                    tileId = animTile.animation[animTile.frame].tileid+1
                                end
                                gfx.spr(tileId, x*mself.tilewidth+ox, y*mself.tileheight+oy)
                            end
                        end
                    end
                elseif layer.type=="objectgroup" then
                    for j, object in ipairs(layer.objects) do
                        local x,y=math.floor(object.x),math.floor(object.y)
                        local color=object.properties["color"] or 1
                        if object.visible then
                            if object.shape=="rectangle" then
                                if object.gid then
                                    local gid=object.gid
                                    local animTile = m.animLookup[gid]
                                    if animTile then
                                        gid = animTile.animation[animTile.frame].tileid+1
                                    end

                                    local gx=(gid-1)*usagi.SPRITE_SIZE
                                    local w=mself.tilesets[1].imagewidth
                                    local gy=math.floor((gid-1)/(w/usagi.SPRITE_SIZE))*usagi.SPRITE_SIZE
                                    local r=math.rad(object.rotation)
                                    gfx.sspr_ex(gx,gy,usagi.SPRITE_SIZE,usagi.SPRITE_SIZE,x+ox,(y-object.height)+oy,object.width,object.height,false,false,r,0,1)
                                else
                                    if object.properties["fill"] then
                                        gfx.rect_fill(x+ox,y+oy,object.width,object.height,color)
                                    else
                                        gfx.rect(x+ox,y+oy,object.width,object.height,color)
                                    end
                                end
                            elseif object.shape=="point" then
                                gfx.px(x+ox,y+oy,color)
                            elseif object.shape=="ellipse" then
                                local r=object.width/2
                                if object.properties["fill"] then
                                    gfx.circ_fill(object.x+r+ox,object.y+r+oy,r,color)
                                else
                                    gfx.circ(object.x+r+ox,object.y+r+oy,r,color)
                                end
                            end
                        end
                    end
                end
        end
    end
    m.draw=function(mself,dx,dy)
        local x,y=dx or 0,dy or 0
        for k,layer in ipairs(mself.layers) do
            m:drawlayer(layer.name,dx,dy)
        end
    end

    m.get=function(mself, layername, x, y)
        for k, layer in ipairs(mself.layers) do
            if layer.name == layername and layer.type=="tilelayer" then
                local index = y * layer.width + x + 1
                local tileId = layer.data[index]
                if tileId == nil then
                    return nil, nil
                end

                local tileProps = nil
                for _, tileset in ipairs(mself.tilesets) do
                    local firstgid = tileset.firstgid or 1
                    local lastgid = firstgid + (tileset.tilecount or 0) - 1
                    if tileId >= firstgid and tileId <= lastgid then
                        local tileIndex = tileId - firstgid + 1
                        local tile = tileset.tiles[tileIndex]
                        if tile and tile.properties then
                            tileProps = tile.properties
                        end
                        break
                    end
                end

                return tileId, tileProps
            end
        end
        return nil, nil
    end

    m.getlayer=function(mself,layername)
        for k, layer in ipairs(mself.layers) do
            if layer.name == layername then
                return layer
            end
        end
        return nil
    end
    
    m.getobject=function(mself,layername,objectname)
        for b,object in pairs(mself:getlayer(layername).objects) do
            if object.name==objectname then
                return object
            end
        end
    end

    m.set=function(mself, layername, x, y, tile)
        for k, layer in ipairs(mself.layers) do
            if layer.name == layername and layer.type=="tilelayer" then
                local index = y * layer.width + x + 1
                layer.data[index]=tile
                return layer.data[index]
            end
        end
    end

    m.bumpInit=function(mself,world)
        mself.tileCols={}
        for a,layer in pairs(mself.layers) do
            local coli=layer.properties and layer.properties.collidable
            if layer.type=="tilelayer" then
                for y = 0,layer.height-1 do
                    for x = 0,layer.width-1 do
                        local tileId=mself:get(layer.name,x,y)
                        if m.collidableTiles[tileId] or coli then
                            table.insert(mself.tileCols,{x=x*mself.tilewidth,y=y*mself.tileheight,id=tileId,properties=m.collidableTiles[tileId]})
                            world:add(mself.tileCols[#mself.tileCols],x*mself.tilewidth,y*mself.tileheight,mself.tilewidth,mself.tileheight)
                        end
                    end
                end
            elseif layer.type=="objectgroup" then
                for j, object in ipairs(layer.objects) do
                    local x,y=math.floor(object.x),math.floor(object.y)
                    if object.shape=="rectangle" and (object.properties.collidable or layer.properties.collidable) then
                        local yy=0
                        object.properties.collidable=true
                        if object.gid then yy=object.height end
                        table.insert(mself.tileCols,{x=x,y=y-yy,id=object.id, properties=object.properties})
                        world:add(mself.tileCols[#mself.tileCols],x,y-yy,object.width,object.height)
                    end
                end
            end
        end
    end

    m.update=function(mself,dt)
        mself.time+=dt
        for tileId,tile in pairs(m.animLookup) do
            tile.time=tile.time+dt*1000
            if tile.time>=tile.animation[tile.frame].duration then
                tile.frame=tile.frame+1
                tile.time=0
                if tile.frame>#tile.animation then
                    tile.frame=1
                end
            end
        end
    end
    
    return m
end

return map