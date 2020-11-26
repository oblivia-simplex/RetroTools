module RetroTools
__precompile__(false)

using StatsBase
using PyCall
Retro = pyimport("retro")

export poke, peek, mem_read, mem_write, mem_blocks, random_address

function kill(env)
    env.render(close=true)
    env.close()
end

function poke(env, address, value)
    poke(env, address=address, value=value)
end

function poke(env; address::Integer, value::Union{UInt8, UInt16})
    if value isa UInt8
        t = "uint8"
    elseif value isa UInt16
        t = "uint16"
    else
        error("Unreachable")
    end
    
    Retro._retro.Memory.assign(env.data.memory, address, t, value)
end

function peek(env, address)
    mem_read(env; address=address, size=1)[1]
end

function mem_read(env; address, size=1)
    blocks = mem_blocks(env)
    filter!(b -> address in b, blocks)
    if isempty(blocks)
        error("Unmapped address. Mapped addresses given by mem_blocks().")
    end
    address += 1 # julia is 1-indexed
    block = blocks[1]
    offset = address - block.start
    Vector{UInt8}(env.data.memory.blocks[block.start][offset:(offset+size-1)])
end


function mem_blocks(env)
    [UInt32(p.first):UInt32(p.first + length(p.second) - 1) for p in env.data.memory.blocks]
end

function random_address(env)
    blocks = mem_blocks(env)
    weights = [1.0 / length(b) for b in blocks]
    block = sample(blocks, ProbabilityWeights(weights))
    UInt32(rand(block))
end

function mem_write(env; address::Integer, data::Vector{UInt8})
    for byte in data
        poke(env, address=address, value=byte)
        address += 1
    end
end


end # module
