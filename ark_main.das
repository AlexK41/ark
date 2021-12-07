require daslib/media

options debugger            // uncomment for debug in VS Code
require daslib/debug        // uncomment for debug in VS Code

let
    BOXSIZE = 10.0
    WIDTH_IN_BRICKS = 50
    HEIGHT_IN_BRICKS = 30
    WORLDWIDTH = float(WIDTH_IN_BRICKS) * BOXSIZE
    WORLDHEIGHT = float(HEIGHT_IN_BRICKS) * BOXSIZE
    BLINK_TIME = 0.1
    DELAY_START = 2.0

var
    RAND_SEED: int4    

struct Box
    pos : float2
    lives : int
    hitTime : float

struct Platform
    pos : float2
    velx : float
    velc : float
    w : float
    h : float

struct Ball
    pos : float2
    vel : float2
    r : float

struct TraceResult
    frac = -1.0f
    n = float2(1.0, 0.0)
    d2 = -1.0

struct IntersectRes
    p : float3
    d = -1.0

struct Side    
    plane : float3
    points : float2[2]

def distplane(plane : float3; p : float2) : float
    return plane.x * p.x + plane.y * p.y + plane.z
    
def collide_box_circle(boxPos : float2; w, h : float; ball : Ball) : TraceResult
    var res = TraceResult()
    let halfW = 0.5 * w
    let halfH = 0.5 * h
    var dir = ball.pos - boxPos - float2(halfW, halfH)
    var adir = abs(dir)
    let r = ball.r

    if adir.x > (halfW + r) || adir.y > (halfH + r)
        return <- res

    if adir.x > halfW && adir.y > halfH
        var n = adir - float2(halfW, halfH)
        var dist2 = length_sq(n)
        if dist2 < r * r
            res.n = normalize(n * float2(sign(dir.x), sign(dir.y)))
            if dot(res.n, ball.vel) < 0.0
                res.frac = 0.5
                res.d2 = dist2
    elif adir.x <= halfW && adir.y > halfH
        var dist = adir.y - halfH
        if dist < r
            var n = float2(0.0, 1.0)
            res.n = n * float2(sign(dir.x), sign(dir.y))
            if dot(res.n, ball.vel) < 0.0
                res.frac = 0.5
                res.d2 = dist * dist
    elif adir.x > halfW && adir.y < halfH
        var dist = adir.x - halfW
        if dist < r
            var n = float2(1.0, 0.0)
            res.n = n * float2(sign(dir.x), sign(dir.y))
            if dot(res.n, ball.vel) < 0.0
                res.frac = 0.5
                res.d2 = dist * dist

    return <- res

def collide_box_box(pos1 : float2; w1, h1 : float; pos2 : float2; w2, h2 : float) : bool
    var hw1 = w1 * 0.5
    var hh1 = h1 * 0.5
    var hw2 = w2 * 0.5
    var hh2 = h2 * 0.5

    var c1 = pos1 + float2(hw1, hh1)
    var c2 = pos2 + float2(hw2, hh2)
    var dir = c2 - c1
    var adir = abs(dir)

    return adir.x < (hw1 + hw1) && adir.y < (hh1 + hh1)

def refl2(v, n : float2) : float2
    return v - 2.0 * n * dot(v, n)

struct World
    ball : Ball
    platform : Platform
    bricks : array<Box>
    startNime : float

var world : World;

def drawBox(x : float; y : float;w : float; h : float; c : float3)
    var c1 = saturate(c - float3(0.3, 0.3, 0.3))
    var c2 = saturate(c + float3(0.3, 0.3, 0.3))

    let b = 1.0
    let hb = 0.5 * b

    fill_rect(x, y + hb, w - hb, h - hb, make_color(c2))
    fill_rect(x + hb, y, w - hb, h - hb, make_color(c1))
    fill_rect(x + hb, y + hb, w - b, h - b, make_color(c))

def drawBall()
    fill_circle(world.ball.pos.x, world.ball.pos.y, world.ball.r, 0xffcfcfcf)
    return

def drawPlatform()
    drawBox(world.platform.pos.x, world.platform.pos.y, world.platform.w, world.platform.h, float3(0.2, 0.8, 0.4))
    return

def getBrickColor(box : Box&) : float3
    var c = float3(0.8, 0.6, 0.4)
    if box.lives == 3
        c = float3(0.2, 0.8, 0.2)
    elif box.lives == 2
        c = float3(0.2, 0.2, 0.8)
    elif box.lives == 1
        c = float3(0.2, 0.8, 0.8)
    elif box.lives <= 0
        c = float3(0.0, 0.8, 0.8)

    var t = get_time_after_start()
    var blink = saturate((t - box.hitTime) / BLINK_TIME)

    c = lerp(float3(1.0, 1.0, 1.0), c, blink)

    return c

def drawBricks
    for b in world.bricks
        var c = getBrickColor(b)
        drawBox(b.pos.x, b.pos.y, BOXSIZE, BOXSIZE, c)

    return

def drawWorld()
    let h = float(get_screen_height())
    let border = [[float2[4] float2(0.0, h); float2(0.0, 0.0); float2(WORLDWIDTH, 0.0); float2(WORLDWIDTH, h)]]
    for i in range(0, 3)
        line(border[i].x, border[i].y, border[i + 1].x, border[i + 1].y, 0xffffffff)
    drawPlatform()
    drawBall()
    drawBricks()
    return

def initBallAndPlatform()    
    world.platform.w = 6.0 * BOXSIZE
    world.platform.h = BOXSIZE
    world.platform.pos = float2(0.5 * (WORLDWIDTH - world.platform.w), WORLDHEIGHT - world.platform.h)
    world.platform.velx = 360.0

    world.ball.r = 0.4 * BOXSIZE
    world.ball.pos = world.platform.pos + float2(0.5 * world.platform.w, -world.ball.r)
    world.ball.vel = float2(20.0, -160.0)
    //world.ball.vel = float2(0.0, -3160.0)

    world.startNime = get_time_after_start()

def initWorld()
    initBallAndPlatform()

    var box : Box;

    for j in range(2, 14)
        let fr = abs(8 - j) + 2
        for i in range(fr, WIDTH_IN_BRICKS - fr)
            box.pos.x = float(i) * BOXSIZE
            box.pos.y = float(j) * BOXSIZE
            box.lives = 1 + random_int(RAND_SEED) % 4
            box.hitTime = 0.0
            push(world.bricks, box)

    return

def updateBall(dt : float)
    var nextPos = world.ball.pos + dt * world.ball.vel

    var ballBBoxPos = min(world.ball.pos,nextPos) - float2(world.ball.r, world.ball.r)
    var ballBBoxSize = abs(world.ball.pos - nextPos) + float2(world.ball.r, world.ball.r) * 2.0

    var collBoxIdxs : array<int>

    var currT = get_time_after_start()

    for i in range(0, length(world.bricks))
        unsafe
            let b& = world.bricks[i]
            if b.lives <= 0
                continue

            if !collide_box_box(b.pos, BOXSIZE, BOXSIZE, ballBBoxPos, ballBBoxSize.x, ballBBoxSize.y)
                continue

            push(collBoxIdxs, i)

    var collidePlatform = collide_box_box(world.platform.pos, world.platform.w, world.platform.h,
                                           ballBBoxPos, ballBBoxSize.x, ballBBoxSize.y)

    let maxStep = 0.25 * world.ball.r
    let dir = nextPos - world.ball.pos
    let dist = sqrt(dot(dir, dir))

    let dirn = normalize(dir)

    var currPos = world.ball.pos
    let  startPos = world.ball.pos
    var d = 0.0
    var hasContact = false
    while !hasContact && d <= dist
        var n = float2(1.0, 0.0)
        var d2 = 100500.0
        var collBoxId = -1
        for i in collBoxIdxs
            let res <- collide_box_circle(world.bricks[i].pos, BOXSIZE, BOXSIZE, world.ball)
            if res.frac > 0.0 && res.d2 < d2
                n = res.n
                d2 = res.d2
                collBoxId = i
                hasContact = true
                
        if hasContact && collBoxId >= 0
            unsafe
                var b& = world.bricks[collBoxId]
                b.hitTime = currT
                b.lives--
                world.ball.vel = refl2(world.ball.vel, n)
                break

        if collidePlatform
            let pres <- collide_box_circle(world.platform.pos, world.platform.w, world.platform.h, world.ball)
            if pres.frac > 0.0
                world.ball.vel = refl2(world.ball.vel, pres.n)
                world.ball.vel.x += world.platform.velc * 0.1
                hasContact = true

        d += maxStep
        currPos = startPos + dirn * min(d, dist)
        world.ball.pos = currPos


    if world.ball.pos.x < world.ball.r && world.ball.vel.x < 0.0
        world.ball.vel.x = -world.ball.vel.x
    elif world.ball.pos.x > (WORLDWIDTH - world.ball.r) && world.ball.vel.x > 0.0
        world.ball.vel.x = -world.ball.vel.x

    if world.ball.pos.y < world.ball.r && world.ball.vel.y < 0.0
        world.ball.vel.y = -world.ball.vel.y

    for i in range(0, length(world.bricks))
        var b = world.bricks[i]
        if b.lives <= 0
            erase(world.bricks, i)
            break

    if world.ball.pos.y > WORLDHEIGHT + 50.0
        initBallAndPlatform()

    return

def updatePlatform(dt : float)
    var d = 0.0
    world.platform.velc = 0.0
    if get_key(VK_LEFT)
        d -= dt;
        world.platform.velc = -world.platform.velx
    if get_key(VK_RIGHT)
        d += dt;
        world.platform.velc = world.platform.velx

    world.platform.pos.x += world.platform.velx * d
    world.platform.pos.x = clamp(world.platform.pos.x, 0.0, WORLDWIDTH - world.platform.w)
    return

def updateWorld(dt : float)    
    if world.startNime + DELAY_START > get_time_after_start()
        return

    updatePlatform(dt)
    updateBall(dt)

    return

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize
    set_window_title("Hello, world!")
    randomize_seed(RAND_SEED)
    initWorld()
    return

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    updateWorld(dt)

    return

// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    let scale = 0.95 * min(float(get_screen_width()) / WORLDWIDTH, float(get_screen_height()) / WORLDHEIGHT)
    setup_2d_camera(0.5 * float2(WORLDWIDTH, WORLDHEIGHT), scale)
    drawWorld()

    return
