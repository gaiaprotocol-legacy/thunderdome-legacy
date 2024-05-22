import { exists } from "https://deno.land/std@0.223.0/fs/mod.ts";
import { serveFile } from "https://deno.land/std@0.223.0/http/file_server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.31.0";

const SUPABASE_URL = "https://dwzrduviqvesskxhtcbu.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3enJkdXZpcXZlc3NreGh0Y2J1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDY3NzY2MzMsImV4cCI6MjAyMjM1MjYzM30.W6MSBY3IRluB66_VkxEAoGu8Z6R77WRVoX9VcMkhlEc";

Deno.serve(async (req) => {
  const path = new URL(req.url).pathname;
  if (path.startsWith("/post/")) {
    const postId = path.split("/")[2];

    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    const { data: posts, error: getPostsError } = await supabase.from("posts")
      .select(
        "*, author(user_id, display_name, avatar, avatar_thumb, stored_avatar, stored_avatar_thumb, x_username)",
      ).eq("id", postId);
    if (getPostsError) throw getPostsError;
    const post = posts?.[0];

    let indexContent = await Deno.readTextFile(Deno.cwd() + "/index.html");

    if (post) {
      let metaTags = `
        <meta name="twitter:card" content="summary_large_image">
        <meta name="twitter:site" content="@ThunderDomeSo">
        <meta name="twitter:title" content="${
        post.author.display_name + " (" + post.author.x_username + ")"
      } on Thunder Dome">
        <meta name="twitter:description" content="${post.message}">
      `;
      if (
        post.rich?.files?.length > 0 &&
        post.rich.files[0].fileType.startsWith("image/")
      ) {
        metaTags += `
          <meta name="twitter:image" content="${post.rich.files[0].url}">
        `;
      }
      indexContent = indexContent.replace(
        "<!-- Twitter Meta Tags -->",
        metaTags,
      );
    }

    return new Response(indexContent, {
      status: 200,
      headers: {
        "content-type": "text/html",
      },
    });
  } else {
    const filePath = Deno.cwd() + path;
    if (path !== "/" && await exists(filePath)) {
      return await serveFile(req, filePath);
    } else {
      return await serveFile(req, Deno.cwd() + "/index.html");
    }
  }
});
