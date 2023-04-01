package xyz.justsoft.video_thumbnail;

import android.content.Context;
import android.graphics.Bitmap;
import android.media.MediaMetadataRetriever;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * VideoThumbnailPlugin
 */
public class VideoThumbnailPlugin implements FlutterPlugin, MethodCallHandler {
    private static String TAG = "ThumbnailPlugin";
    private static final int HIGH_QUALITY_MIN_VAL = 70;

    private Context context;
    private ExecutorService executor;
    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        executor = Executors.newCachedThreadPool();
        channel = new MethodChannel(binding.getBinaryMessenger(), "plugins.justsoft.xyz/video_thumbnail");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        executor.shutdown();
        executor = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
        final Map<String, Object> args = call.arguments();

        final String video = (String) args.get("video");
        final HashMap<String, String> headers = (HashMap<String, String>) args.get("headers");
        final int format = (int) args.get("format");
        final int maxh = (int) args.get("maxh");
        final int maxw = (int) args.get("maxw");
        final int timeMs = (int) args.get("timeMs");
        final int quality = (int) args.get("quality");
        final String method = call.method;

        executor.execute(new Runnable() {
            @Override
            public void run() {
                Object thumbnail = null;
                boolean handled = false;
                Exception exc = null;

                try {
                    if (method.equals("file")) {
                        final String path = (String) args.get("path");
                        thumbnail = buildThumbnailFile(video, headers, path, format, maxh, maxw, timeMs, quality);
                        handled = true;

                    } else if (method.equals("data")) {
                        thumbnail = buildThumbnailData(video, headers, format, maxh, maxw, timeMs, quality);
                        handled = true;
                    }
                } catch (Exception e) {
                    exc = e;
                }

                onResult(result, thumbnail, handled, exc);
            }
        });
    }

    private static Bitmap.CompressFormat intToFormat(int format) {
        switch (format) {
            default:
            case 0:
                return Bitmap.CompressFormat.JPEG;
            case 1:
                return Bitmap.CompressFormat.PNG;
            case 2:
                return Bitmap.CompressFormat.WEBP;
        }
    }

    private static String formatExt(int format) {
        switch (format) {
            default:
            case 0:
                return "jpg";
            case 1:
                return "png";
            case 2:
                return "webp";
        }
    }

    private byte[] buildThumbnailData(final String vidPath, final HashMap<String, String> headers, int format, int maxh,
            int maxw, int timeMs, int quality) {
        // Log.d(TAG, String.format("buildThumbnailData( format:%d, maxh:%d, maxw:%d,
        // timeMs:%d, quality:%d )", format, maxh, maxw, timeMs, quality));
        Bitmap bitmap = createVideoThumbnail(vidPath, headers, maxh, maxw, timeMs);
        if (bitmap == null)
            throw new NullPointerException();

        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(intToFormat(format), quality, stream);
        bitmap.recycle();
        if (bitmap == null)
            throw new NullPointerException();
        return stream.toByteArray();
    }

    private String buildThumbnailFile(final String vidPath, final HashMap<String, String> headers, String path,
            int format, int maxh, int maxw, int timeMs,
            int quality) {
        // Log.d(TAG, String.format("buildThumbnailFile( format:%d, maxh:%d, maxw:%d,
        // timeMs:%d, quality:%d )", format, maxh, maxw, timeMs, quality));
        final byte bytes[] = buildThumbnailData(vidPath, headers, format, maxh, maxw, timeMs, quality);
        final String ext = formatExt(format);
        final int i = vidPath.lastIndexOf(".");
        String fullpath = vidPath.substring(0, i + 1) + ext;
        final boolean isLocalFile = (vidPath.startsWith("/") || vidPath.startsWith("file://"));

        if (path == null && !isLocalFile) {
            path = context.getCacheDir().getAbsolutePath();
        }

        if (path != null) {
            if (path.endsWith(ext)) {
                fullpath = path;
            } else {
                // try to save to same folder as the vidPath
                final int j = fullpath.lastIndexOf("/");

                if (path.endsWith("/")) {
                    fullpath = path + fullpath.substring(j + 1);
                } else {
                    fullpath = path + fullpath.substring(j);
                }
            }
        }

        try {
            FileOutputStream f = new FileOutputStream(fullpath);
            f.write(bytes);
            f.close();
            Log.d(TAG, String.format("buildThumbnailFile( written:%d )", bytes.length));
        } catch (java.io.IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
        return fullpath;
    }

    private void onResult(final Result result, final Object thumbnail, final boolean handled, final Exception e) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (!handled) {
                    result.notImplemented();
                    return;
                }

                if (e != null) {
                    e.printStackTrace();
                    result.error("exception", e.getMessage(), null);
                    return;
                }

                result.success(thumbnail);
            }
        });
    }

    private static void runOnUiThread(Runnable runnable) {
        new Handler(Looper.getMainLooper()).post(runnable);
    }

    /**
     * Create a video thumbnail for a video. May return null if the video is corrupt
     * or the format is not supported.
     *
     * @param video   the URI of video
     * @param targetH the max height of the thumbnail
     * @param targetW the max width of the thumbnail
     */
    public Bitmap createVideoThumbnail(final String video, final HashMap<String, String> headers, int targetH,
            int targetW, int timeMs) {
        Bitmap bitmap = null;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            if (video.startsWith("/")) {
                setDataSource(video, retriever);
            } else if (video.startsWith("file://")) {
                setDataSource(video.substring(7), retriever);
            } else {
                retriever.setDataSource(video, (headers != null) ? headers : new HashMap<String, String>());
            }

            if (targetH != 0 || targetW != 0) {
                if (android.os.Build.VERSION.SDK_INT >= 27 && targetH != 0 && targetW != 0) {
                    // API Level 27
                    bitmap = retriever.getScaledFrameAtTime(timeMs * 1000, MediaMetadataRetriever.OPTION_CLOSEST,
                            targetW, targetH);
                } else {
                    bitmap = retriever.getFrameAtTime(timeMs * 1000, MediaMetadataRetriever.OPTION_CLOSEST);
                    if (bitmap != null) {
                        int width = bitmap.getWidth();
                        int height = bitmap.getHeight();
                        if (targetW == 0) {
                            targetW = Math.round(((float) targetH / height) * width);
                        }
                        if (targetH == 0) {
                            targetH = Math.round(((float) targetW / width) * height);
                        }
                        Log.d(TAG, String.format("original w:%d, h:%d => %d, %d", width, height, targetW, targetH));
                        bitmap = Bitmap.createScaledBitmap(bitmap, targetW, targetH, true);
                    }
                }
            } else {
                bitmap = retriever.getFrameAtTime(timeMs * 1000, MediaMetadataRetriever.OPTION_CLOSEST);
            }
        } catch (IllegalArgumentException ex) {
            ex.printStackTrace();
        } catch (RuntimeException ex) {
            ex.printStackTrace();
        } catch (IOException ex) {
            ex.printStackTrace();
        } finally {
            try {
                retriever.release();
            } catch (RuntimeException | IOException ex) {
                ex.printStackTrace();
            }
        }

        return bitmap;
    }

    private static void setDataSource(String video, final MediaMetadataRetriever retriever) throws IOException {
        File videoFile = new File(video);
        FileInputStream inputStream = new FileInputStream(videoFile.getAbsolutePath());
        retriever.setDataSource(inputStream.getFD());
    }
}
