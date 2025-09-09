shader_type canvas_item;

uniform sampler2D mask_texture; 
uniform vec4 polygon_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float blur_range : hint_range(0.001, 0.5) = 0.05; // 新增：控制羽化的实际距离

void fragment() {
    // 从遮罩纹理中获取当前像素的颜色
    float mask_value = texture(mask_texture, UV).r;
    
    // 使用相邻像素的颜色来计算边缘
    // 因为纹理是纯黑和纯白的，边缘的颜色值是突变的
    // 我们需要通过相邻像素来估算当前像素离边缘有多远
    vec2 pixel_size = 1.0 / vec2(textureSize(mask_texture, 0));
    
    // 获取当前像素四周的 mask 值
    float mask_left = texture(mask_texture, UV - vec2(pixel_size.x, 0.0)).r;
    float mask_right = texture(mask_texture, UV + vec2(pixel_size.x, 0.0)).r;
    float mask_up = texture(mask_texture, UV - vec2(0.0, pixel_size.y)).r;
    float mask_down = texture(mask_texture, UV + vec2(0.0, pixel_size.y)).r;
    
    // 计算当前像素到边缘的距离（近似值）
    // 这个值在边缘处接近0，在多边形内部或外部会迅速增大
    float dist_from_edge = min(abs(mask_value - mask_left), abs(mask_value - mask_right));
    dist_from_edge = min(dist_from_edge, abs(mask_value - mask_up));
    dist_from_edge = min(dist_from_edge, abs(mask_value - mask_down));
    
    // 根据距离创建一个羽化遮罩
    // 当像素距离边缘小于 blur_range 时，开始平滑过渡
    float blur_mask = smoothstep(0.0, blur_range, dist_from_edge);
    
    // 根据 mask_value（0或1）来决定羽化的方向（内或外）
    // 并且根据 blur_mask 的值进行混合
    float final_alpha;
    if (mask_value < 0.5) {
        // 在多边形内部
        final_alpha = blur_mask;
    } else {
        // 在多边形外部
        final_alpha = 1.0 - blur_mask;
    }
    
    // 设置最终的颜色和透明度
    COLOR = vec4(polygon_color.rgb, final_alpha);
}
