import Foundation

/// Catalogue of built-in HTML/JS particle and shader wallpapers.
/// Each entry contains a self-contained HTML string with embedded CSS and JS.
enum BuiltinWallpaper: String, CaseIterable {
    case particleNetwork  = "✨ Particle Network"
    case matrixRain       = "🟩 Matrix Rain"
    case aurora           = "🌌 Aurora Borealis"
    case galaxyField      = "🌠 Galaxy Field"

    var html: String {
        switch self {
        case .particleNetwork: return BuiltinHTML.particleNetwork
        case .matrixRain:      return BuiltinHTML.matrixRain
        case .aurora:          return BuiltinHTML.aurora
        case .galaxyField:     return BuiltinHTML.galaxyField
        }
    }
}

// MARK: - HTML Source Code for Each Wallpaper

enum BuiltinHTML {

    // -------------------------------------------------------------------------
    // PARTICLE NETWORK — glowing nodes connected by translucent lines
    // -------------------------------------------------------------------------
    static let particleNetwork = """
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>*{margin:0;padding:0;overflow:hidden}html,body{width:100%;height:100%;background:#060c1a}canvas{display:block}</style>
    </head><body><canvas id="c"></canvas><script>
    const cvs=document.getElementById('c'),ctx=cvs.getContext('2d');
    let W=cvs.width=innerWidth,H=cvs.height=innerHeight;
    const N=120,D=170,SPD=0.4,HUES=[195,215,240,265,290];
    class P{constructor(){this.reset()}reset(){
      this.x=Math.random()*W;this.y=Math.random()*H;
      this.vx=(Math.random()-.5)*SPD;this.vy=(Math.random()-.5)*SPD;
      this.r=Math.random()*2+.8;this.hue=HUES[Math.random()*HUES.length|0];
      this.a=.5+Math.random()*.5}
    move(){
      this.x+=this.vx;this.y+=this.vy;
      if(this.x<-10||this.x>W+10)this.vx*=-1;
      if(this.y<-10||this.y>H+10)this.vy*=-1}
    draw(){
      ctx.shadowBlur=16;ctx.shadowColor=`hsla(${this.hue},100%,70%,.9)`;
      ctx.beginPath();ctx.arc(this.x,this.y,this.r,0,Math.PI*2);
      ctx.fillStyle=`hsla(${this.hue},100%,80%,${this.a})`;ctx.fill()}}
    const ps=Array.from({length:N},()=>new P());
    /* static star field */
    ctx.fillStyle='#060c1a';ctx.fillRect(0,0,W,H);
    for(let i=0;i<250;i++){
      ctx.beginPath();ctx.arc(Math.random()*W,Math.random()*H,Math.random()*1.2,0,Math.PI*2);
      ctx.fillStyle=`rgba(255,255,255,${.1+Math.random()*.4})`;ctx.fill()}
    function frame(){
      ctx.fillStyle='rgba(6,12,26,.18)';ctx.fillRect(0,0,W,H);
      ctx.shadowBlur=0;
      for(let i=0;i<ps.length;i++){for(let j=i+1;j<ps.length;j++){
        const dx=ps[i].x-ps[j].x,dy=ps[i].y-ps[j].y,d=Math.hypot(dx,dy);
        if(d<D){ctx.beginPath();ctx.moveTo(ps[i].x,ps[i].y);ctx.lineTo(ps[j].x,ps[j].y);
          ctx.strokeStyle=`rgba(130,190,255,${(1-d/D)*.3})`;ctx.lineWidth=.8;ctx.stroke()}}}
      ps.forEach(p=>{p.move();p.draw()});
      requestAnimationFrame(frame)}
    frame();
    </script></body></html>
    """

    // -------------------------------------------------------------------------
    // MATRIX RAIN — classic green falling characters with glow
    // -------------------------------------------------------------------------
    static let matrixRain = """
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>*{margin:0;padding:0;overflow:hidden}html,body{width:100%;height:100%;background:#000}canvas{display:block}</style>
    </head><body><canvas id="c"></canvas><script>
    const cvs=document.getElementById('c'),ctx=cvs.getContext('2d');
    let W=cvs.width=innerWidth,H=cvs.height=innerHeight;
    const SZ=18,COLS=Math.floor(W/SZ);
    const CHARS='アカサタナハマヤラワイキシチニヒミリヰウクスツヌフムユルウエケセテネヘメレヱオコソトノホモヨロヲンガザダバパABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const drops=Array(COLS).fill(0).map(()=>Math.random()*-100|0);
    const speeds=Array(COLS).fill(0).map(()=>Math.random()*.5+.3);
    function frame(){
      ctx.fillStyle='rgba(0,0,0,.04)';ctx.fillRect(0,0,W,H);
      for(let i=0;i<COLS;i++){
        const ch=CHARS[Math.random()*CHARS.length|0];
        const y=drops[i]*SZ;
        /* bright leading char */
        ctx.shadowBlur=12;ctx.shadowColor='#0f0';
        ctx.fillStyle='#cfc';ctx.font=`bold ${SZ}px monospace`;
        ctx.fillText(ch,i*SZ,y);
        /* trailing chars — dimmer */
        ctx.shadowBlur=4;ctx.shadowColor='#0a0';
        ctx.fillStyle='#0f0';
        ctx.fillText(CHARS[Math.random()*CHARS.length|0],i*SZ,y-SZ);
        drops[i]+=speeds[i];
        if(y>H&&Math.random()>.975)drops[i]=0}
      requestAnimationFrame(frame)}
    frame();
    </script></body></html>
    """

    // -------------------------------------------------------------------------
    // AURORA BOREALIS — multi-layer sinusoidal wave shader
    // -------------------------------------------------------------------------
    static let aurora = """
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>*{margin:0;padding:0;overflow:hidden}html,body{width:100%;height:100%;background:#010810}canvas{display:block}</style>
    </head><body><canvas id="c"></canvas><script>
    const cvs=document.getElementById('c'),ctx=cvs.getContext('2d');
    let W=cvs.width=innerWidth,H=cvs.height=innerHeight;
    /* Aurora layers config */
    const LAYERS=[
      {hue:150,sat:90,spd:.0004,amp:.18,freq:.8,phase:0,   y:.38,opa:.55},
      {hue:185,sat:85,spd:.0006,amp:.14,freq:1.2,phase:1.2, y:.48,opa:.45},
      {hue:260,sat:80,spd:.0003,amp:.12,freq:.6, phase:2.5, y:.42,opa:.35},
      {hue:130,sat:70,spd:.0007,amp:.10,freq:1.6,phase:3.8, y:.54,opa:.30},
    ];
    /* draw starfield once */
    ctx.fillStyle='#010810';ctx.fillRect(0,0,W,H);
    for(let i=0;i<350;i++){
      const x=Math.random()*W,y=Math.random()*H*.7;
      ctx.beginPath();ctx.arc(x,y,Math.random()*.9,0,Math.PI*2);
      ctx.fillStyle=`rgba(255,255,255,${.05+Math.random()*.35})`;ctx.fill()}
    let t=0;
    function drawLayer(l){
      const pts=[];
      for(let x=0;x<=W+2;x+=2){
        const rawY=H*l.y+Math.sin((x/W)*Math.PI*2*l.freq+t*l.spd+l.phase)*H*l.amp
                        +Math.sin((x/W)*Math.PI*3.3*l.freq+t*l.spd*1.7)*H*l.amp*.35;
        pts.push({x,y:rawY})}
      const grad=ctx.createLinearGradient(0,H*l.y-H*l.amp*1.5,0,H*l.y+H*l.amp*2);
      grad.addColorStop(0,`hsla(${l.hue},${l.sat}%,70%,0)`);
      grad.addColorStop(.4,`hsla(${l.hue},${l.sat}%,60%,${l.opa})`);
      grad.addColorStop(.7,`hsla(${l.hue+20},${l.sat-10}%,50%,${l.opa*.6})`);
      grad.addColorStop(1,`hsla(${l.hue},${l.sat}%,40%,0)`);
      ctx.beginPath();ctx.moveTo(0,H);
      pts.forEach(p=>ctx.lineTo(p.x,p.y));
      ctx.lineTo(W,H);ctx.closePath();
      ctx.fillStyle=grad;ctx.fill()}
    function frame(){
      /* re-stamp dark sky so old aurora fades */
      ctx.fillStyle='rgba(1,8,16,.55)';ctx.fillRect(0,0,W,H);
      LAYERS.forEach(drawLayer);
      t++;requestAnimationFrame(frame)}
    frame();
    </script></body></html>
    """

    // -------------------------------------------------------------------------
    // GALAXY FIELD — rotating star clusters with nebula glow
    // -------------------------------------------------------------------------
    static let galaxyField = """
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>*{margin:0;padding:0;overflow:hidden}html,body{width:100%;height:100%;background:#000005}canvas{display:block}</style>
    </head><body><canvas id="c"></canvas><script>
    const cvs=document.getElementById('c'),ctx=cvs.getContext('2d');
    let W=cvs.width=innerWidth,H=cvs.height=innerHeight;
    const CX=W/2,CY=H/2;
    const STARS=3200,ARMS=3,ARM_TWIST=3.5,SCATTER=.22,CORE_SIZE=.12;
    function randNorm(){return(Math.random()+Math.random()+Math.random()-1.5)*.7}
    /* build star data once */
    const stars=[];
    for(let i=0;i<STARS;i++){
      const arm=Math.floor(Math.random()*ARMS);
      const rRaw=Math.pow(Math.random(),.6);
      const r=rRaw*(Math.min(W,H)*.46);
      const theta=(arm/ARMS)*Math.PI*2+rRaw*ARM_TWIST+randNorm()*SCATTER;
      const x=CX+r*Math.cos(theta)+randNorm()*r*SCATTER;
      const y=CY+r*Math.sin(theta)+randNorm()*r*SCATTER;
      /* core = bluer/whiter; outer = redder/dimmer */
      const hue=rRaw<CORE_SIZE?200+Math.random()*60:30+Math.random()*60;
      const bright=rRaw<CORE_SIZE?90:50+Math.random()*30;
      const alpha=(rRaw<CORE_SIZE?.9:.15+Math.random()*.55)*(1-rRaw*.5);
      stars.push({baseX:x-CX,baseY:y-CY,r:Math.random()*(.9+rRaw*.4)+.3,hue,bright,alpha,rRaw})}
    /* nebula splats */
    const nebulae=[
      {dx:-.18,dy:-.12,hue:240,r:.22,a:.12},{dx:.15,dy:.08,hue:300,r:.18,a:.10},
      {dx:-.06,dy:.2, hue:180,r:.15,a:.08}];
    let angle=0;
    function drawNebula(){
      for(const n of nebulae){
        const gx=CX+n.dx*W,gy=CY+n.dy*H,gr=n.r*Math.min(W,H);
        const g=ctx.createRadialGradient(gx,gy,0,gx,gy,gr);
        g.addColorStop(0,`hsla(${n.hue},80%,60%,${n.a})`);
        g.addColorStop(1,'transparent');
        ctx.fillStyle=g;ctx.fillRect(0,0,W,H)}}
    function frame(){
      ctx.fillStyle='rgba(0,0,5,.95)';ctx.fillRect(0,0,W,H);
      drawNebula();
      /* core glow */
      const cg=ctx.createRadialGradient(CX,CY,0,CX,CY,Math.min(W,H)*.12);
      cg.addColorStop(0,'rgba(200,210,255,.45)');cg.addColorStop(1,'transparent');
      ctx.fillStyle=cg;ctx.fillRect(0,0,W,H);
      const cos=Math.cos(angle),sin=Math.sin(angle);
      for(const s of stars){
        const rx=s.baseX*cos-s.baseY*sin+CX;
        const ry=s.baseX*sin+s.baseY*cos+CY;
        ctx.shadowBlur=s.rRaw<.15?8:3;
        ctx.shadowColor=`hsla(${s.hue},100%,80%,${s.alpha})`;
        ctx.beginPath();ctx.arc(rx,ry,s.r,0,Math.PI*2);
        ctx.fillStyle=`hsla(${s.hue},80%,${s.bright}%,${s.alpha})`;ctx.fill()}
      angle+=.00012;requestAnimationFrame(frame)}
    frame();
    </script></body></html>
    """
}
