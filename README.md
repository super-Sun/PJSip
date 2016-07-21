# PJSip
PJSip开发。

#3.2 传来的通话：

用call setting启用或拒绝video（pjsua_call_setting，via vid_cnt setting）

API：

pjsua_call_answer2() (so for example, to reject the video, set vid_cnt to 0 and call pjsua_call_answer2()).


但要显示该视频，以及传出视频，则需要另设。


#3.2.1 自动显示来的视频：

pjsua_acc_config cfg;pjsua_acc_config_default(&cfg);cfg.vid_in_auto_show = PJ_TRUE;

#3.2.2 手动设置，显示或隐藏来的视频：

1.用pjsua_call_get_vid_stream_idx()来索引出呼叫传来的媒体流

2.用pjsua_call_info，根据索引定位到流，然后获得windowID关联到视频。

int vid_idx;pjsua_vid_win_id wid;vid_idx = pjsua_call_get_vid_stream_idx(call_id);if (vid_idx >= 0) {    pjsua_call_info ci;    pjsua_call_get_info(call_id, &ci);    wid = ci.media[vid_idx].stream.vid.win_in;}

3.有了windowID，运用 pjsua_vid_win_get_info()来获得关联的视频，然后用本机API来显示窗口，或用pjsua_vid_win_set_show() 


#3.2.3 控制传来的视频流：

以上提到的只是在本地改变视频，但也可以通过pjsua_call_set_vid_strm()来操作对方传的视频流。

具有以下操作：（改变媒体方向、关闭媒体流、增加流）

PJSUA_CALL_VID_STRM_CHANGE_DIR: change the media direction (e.g. to "sendonly", or even "inactive")
PJSUA_CALL_VID_STRM_REMOVE: remove the media stream altogether by settings its port to zero
PJSUA_CALL_VID_STRM_ADD: add new video media stream

由于这些操作是导致远程改变的，所以得过一会才能生效，可以运行回调函数on_call_media_state()来监视状态。


#3.3 呼出的通话：

#3.3.1

呼出通话前把 pjsua_call_setting.flag 设置成 PJSUA_CALL_INCLUDE_DISABLED_MEDIA ，意味着禁止视频。

传出的视频跟传入的是分开操作的，而且也不会默认开启，就算呼入请求是包含视频的。

由 pjsua_acc_config.vid_out_auto_transmit 来设置传出视频，默认是 PJ_FALSE. 设为 PJ_TRUE 就可以开启所有呼出通话和带视频的呼入通话的视频传出。

#3.3.2 默认的捕获设备：

在 pjsua_acc_config.vid_cap_dev 设置默认捕获设备，在这里设好过在后面的所有API里面设（-_-!神马意思）。

#3.3.3 控制传出媒体流：

用 pjsua_call_set_vid_strm()

    PJSUA_CALL_VID_STRM_ADD: add a new video stream
    PJSUA_CALL_VID_STRM_REMOVE: remove video stream (set port to zero)
    PJSUA_CALL_VID_STRM_CHANGE_DIR: change direction or deactivate (i.e. set direction to "inactive")
    PJSUA_CALL_VID_STRM_CHANGE_CAP_DEV: change capture device
    PJSUA_CALL_VID_STRM_START_TRANSMIT: start previously stopped transmission
    PJSUA_CALL_VID_STRM_STOP_TRANSMIT: stop transmission

设置vid_cnt of pjsua_call_setting 可以增删视频。。。


#3.5 视频窗口的工作：

关于视频窗口：

在呼叫中，传入的视频流的视频窗口是由 pjsua_call_info 结构体控制的

预览窗口要关联捕获设备可以通过查询 pjsua_vid_preview_get_win()

另外，应用程序也可以利用 pjsua_vid_enum_wins() 来列举所有视频窗口

应用程序可以用 pjsua_vid_win_get_info() 获得 pjsua_vid_win_info 。大多数应用程序会对一个窗口的属性感兴趣，就是本地窗口句柄native window handle。video handle由pjsua_vid_win_info里面的 pjmedia_vid_dev_hwnd 结构体控制。利用这个video handle，应用程序可以把video window 嵌入到 GUI 。另外，pj库也提供了一些常用API来操作窗口，诸如pjsua_vid_win_set_show()，pjsua_vid_win_set_size()等。但这些API不担保有效，因为这取决于底层设备。

#3.6 修改视频电话的视频编解码器的参数：

在 pjmedia_vid_codec_param 里面制定视频编解码参数。可以分别设置编码和解码两个方向的参数，更改后，用pjsua_vid_codec_set_param()使其生效。

const pj_str_t codec_id = {"H264", 4};pjmedia_vid_codec_param param;pjsua_vid_codec_get_param(&codec_id, &param);/* Modify param here */...pjsua_vid_codec_set_param(&codec_id, &param);

#3.6.1 大小与分辨率：{

    编码：pjmedia_vid_codec_param.enc_fmt.det.vid.size

    /* Sending 1280 x 720 */

    param.enc_fmt.det.vid.size.w = 1280;

    param.enc_fmt.det.vid.size.h = 720;

    但这可能要根据远程端的能力来调整，比如，如果远程信号说他最高支持640*480，而这里设了1280*720，那么将会是640*480生效。


    解码：

    1.把 pjmedia_vid_codec_param.dec_fmt.det.vid.size 设为最高预期的想要远方传来的分辨率大小。

    2.通过fmtp（ pjmedia_vid_codec_param.dec_fmtp ）向远程端发信号来配置。

            H263-1998, e.g:

        /* 1st preference: 352 x 288 (CIF) */

        param.dec_fmtp.param[n].name = pj_str("CIF");

        /* The value actually specifies framerate, see framerate section below */

        param.dec_fmtp.param[n].val = pj_str("1");

        /* 2nd preference: 176 x 144 (QCIF) */

        param.dec_fmtp.param[n+1].name = pj_str("QCIF");

        /* The value actually specifies framerate, see framerate section below */

        param.dec_fmtp.param[n+1].val = pj_str("1");

            H264, the size is implicitly specified in H264 level (check the standard specification or ?this) and on SDP, the H264 level is signalled via H264 SDP fmtp ?profile-level-id, e.g:

        /* Can receive up to 1280×720 @30fps */

        param.dec_fmtp.param[n].name = pj_str("profile-level-id");

        /* Set the profile level to "1f", which means level 3.1 */

        param.dec_fmtp.param[n].val = pj_str("xxxx1f");

PJSIP Video Users Guide （PJSIP视频用户指南） - kai7613 - 天空安静

         

}

#3.6.2 帧速率：{

    编码方向：pjmedia_vid_codec_param.enc_fmt.det.vid.fps

    /* Sending @30fps */

    param.enc_fmt.det.vid.fps.num   = 30;

    param.enc_fmt.det.vid.fps.denum = 1;

    如果建立通话前，视频已经开始预览，那么将会使用设备的默认帧速率，并且沿用到通话中，而且不管此处如何设置帧速率，都不会有所改变。解决的方法只能是在建立媒体前先禁用预览再重新启用媒体。

    解码方向：

    1.pjmedia_vid_codec_param.dec_fmt.det.vid.fps设为预期的最高值。

    2.通过fmtp（ pjmedia_vid_codec_param.dec_fmtp ）向远程端发信号来配置。

    e.g.同上设置分辨率的部分。

}

#3.6.3 比特率：{

    /* Bitrate range preferred: 512-1024kbps */

    param.enc_fmt.det.vid.avg_bps = 512000;

    param.enc_fmt.det.vid.max_bps = 1024000;

    比特率是双方向对称的。

    调整比特率设置其实就是在调整SDP。

    编码方向的比特率将会受对方在SDP中协定的最大比特率限制。

    如果渴望指定一个比特率，可以通过SDP fmtp手动设置，如下：

    /* H263 specific maximum bitrate 512kbps */

    param.dec_fmtp.param[n].name = pj_str("MaxBR");

    param.dec_fmtp.param[n].val = pj_str("5120"); /* = max_bps / 100 */

}


#5. 视频的一些API：

5.1 设备枚举API：

/**获得系统中的视频设备数量 * Get the number of video devices installed in the system. *返回：设备数量 * @return		The number of devices. */PJ_DECL(unsigned) pjsua_vid_dev_count(void);

/**根据索引取得设备信息 * Retrieve the video device info for the specified device index. * * @param id		The device index.  设备索引 * @param vdi		Device info to be initialized.  存放信息的结构体 * * @return		PJ_SUCCESS on success, or the appropriate error code. */PJ_DECL(pj_status_t) pjsua_vid_dev_get_info(pjmedia_vid_dev_index id,                                            pjmedia_vid_dev_info *vdi);

/**枚举系统中所有视频设备 * Enum all video devices installed in the system. * * @param info		Array of info to be initialized. 存放设备信息的数组 * @param count		On input, specifies max elements in the array. 传入时，指定数组的最大值 *			On return, it contains actual number of elements   传回来实际的数量 *			that have been initialized. * * @return		PJ_SUCCESS on success, or the appropriate error code. */PJ_DECL(pj_status_t) pjsua_vid_enum_devs(pjmedia_vid_dev_info info[],					 unsigned *count);

/**刷新系统中的设备列表，这将可能导致设备索引号的重新编排，但不影响已经使用中的媒体流。刷新后，要注意所有的索引pjmedia_vid_dev_index变量已经失效，调用以索引作为参数的函数就要尤其注意。 * Refresh the list of video devices installed in the system. This function * will only refresh the list of videoo device so all active video streams will * be unaffected. After refreshing the device list, application MUST make sure * to update all index references to video devices (i.e. all variables of type * pjmedia_vid_dev_index) before calling any function that accepts video device * index as its parameter. * * @return		PJ_SUCCESS on successful operation or the appropriate *			error code. */PJ_DECL(pj_status_t) pjmedia_vid_dev_refresh(void);

5.2 视频预览API：

要开始视频预览前，要先用pjsua_vid_preview_param_default()初始化以下结构体：

/** * Parameters for starting video preview with pjsua_vid_preview_start(). * Application should initialize this structure with * pjsua_vid_preview_param_default(). */typedef struct pjsua_vid_preview_param{    /**视频渲染器（即播放设备）的ID。     * Device ID for the video renderer to be used for rendering the     * capture stream for preview.     */    pjmedia_vid_dev_index	rend_id;} pjsua_vid_preview_param;

/**为指定的捕获设备开启视频预览窗口 * Start video preview window for the specified capture device. * * @param id		The capture device ID where its preview will be * 			started. 捕获设备的ID * @param prm		Optional video preview parameters. Specify NULL * 			to use default values.预览选项，NULL为默认 * * @return		PJ_SUCCESS on success, or the appropriate error code. */PJ_DECL(pj_status_t) pjsua_vid_preview_start(pjmedia_vid_dev_index id,                                             pjsua_vid_preview_param *prm);

/**如果有的话，获取与捕获设备关联了的预览窗口handle * Get the preview window handle associated with the capture device, if any. * * @param id		The capture device ID. * * @return		The window ID of the preview window for the * 			specified capture device ID, or NULL if preview * 			does not exist. */PJ_DECL(pjsua_vid_win_id) pjsua_vid_preview_get_win(pjmedia_vid_dev_index id);

/**停止视频预览 * Stop video preview. * * @param id		The capture device ID. * * @return		PJ_SUCCESS on success, or the appropriate error code. */PJ_DECL(pj_status_t) pjsua_vid_preview_stop(pjmedia_vid_dev_index id);

5.3 视频配置：

视频启不启用在 pjsua_call_setting.vid_cnt中设置，一般为1即启用，0为不启用。

视频的大部分设置都在 pjsua_acc_config 的以下域：

pj_bool_t        vid_in_auto_show;  指定传入的视频是否自动显示在屏幕上。 PJ_TRUE / PJ_FALSE

pjsua_call_get_info();  枚举媒体流

pj_bool_t        vid_out_auto_transmit;  设定当有视频来电，或拨出电话时，是否默认激活视频传出。PJ_TRUE / PJ_FALSE

无论上面这个怎么设置，都可以用 pjsua_call_set_vid_strm(); 来开始或停止视频传出。

pjmedia_vid_dev_index vid_cap_dev;  指定使用的捕获设备。Default: PJMEDIA_VID_DEFAULT_CAPTURE_DEV

pjmedia_vid_dev_index vid_rend_dev;  指定使用的显示设备。Default: PJMEDIA_VID_DEFAULT_RENDER_DEV


5.4 视频通话操作：


除了以上的视频配置操作，还可以在呼叫时用pjsua_call_set_vid_strm()来配置视频。

要配置时，首先要利用以下两个结构体的其中一个：

typedef enum pjsua_call_vid_strm_op{    /**     * No operation     */    PJSUA_CALL_VID_STRM_NO_OP,    /**增加视频流     * Add a new video stream. This will add a new m=video line to     * the media, regardless of whether existing video is/are present     * or not.  This will cause re-INVITE or UPDATE to be sent to remote     * party.     */    PJSUA_CALL_VID_STRM_ADD,    /**移除视频流     * Remove/disable an existing video stream. This will     * cause re-INVITE or UPDATE to be sent to remote party.     */    PJSUA_CALL_VID_STRM_REMOVE,    /**改变流方向     * Change direction of a video stream. This operation can be used     * to activate or deactivate an existing video media. This will     * cause re-INVITE or UPDATE to be sent to remote party.     */    PJSUA_CALL_VID_STRM_CHANGE_DIR,    /**改变捕获设备     * Change capture device of a video stream.  This will not send     * re-INVITE or UPDATE to remote party.     */    PJSUA_CALL_VID_STRM_CHANGE_CAP_DEV,    /**开启流传输     * Start transmitting video stream. This will cause previously     * stopped stream to start transmitting again. Note that no     * re-INVITE/UPDATE is to be transmitted to remote since this     * operation only operates on local stream.     */    PJSUA_CALL_VID_STRM_START_TRANSMIT,    /**停止流传输     * Stop transmitting video stream. This will cause the stream to     * be paused in TX direction, causing it to stop sending any video     * packets. No re-INVITE/UPDATE is to be transmitted to remote     * with this operation.     */    PJSUA_CALL_VID_STRM_STOP_TRANSMIT,    /**传输关键帧     * Send keyframe in the video stream. This will force the stream to     * generate and send video keyframe as soon as possible. No     * re-INVITE/UPDATE is to be transmitted to remote with this operation.     */    PJSUA_CALL_VID_STRM_SEND_KEYFRAME} pjsua_call_vid_strm_op;

/** * Parameters for video stream operation on a call. */typedef struct pjsua_call_vid_strm_op_param{    /**     * Specify the media stream index. This can be set to -1 to denote     * the default video stream in the call, which is the first active     * video stream or any first video stream if none is active.     *     * This field is valid for all video stream operations, except     * PJSUA_CALL_VID_STRM_ADD.     *     * Default: -1 (first active video stream, or any first video stream     *              if none is active)     */    int med_idx;    /**     * Specify the media stream direction.     *     * This field is valid for the following video stream operations:     * PJSUA_CALL_VID_STRM_ADD and PJSUA_CALL_VID_STRM_CHANGE_DIR.     *     * Default: PJMEDIA_DIR_ENCODING_DECODING     */    pjmedia_dir dir;    /**     * Specify the video capture device ID. This can be set to     * PJMEDIA_VID_DEFAULT_CAPTURE_DEV to specify the default capture     * device as configured in the account.     *     * This field is valid for the following video stream operations:     * PJSUA_CALL_VID_STRM_ADD and PJSUA_CALL_VID_STRM_CHANGE_CAP_DEV.     *     * Default: capture device configured in account.     */    pjmedia_vid_dev_index cap_dev;} pjsua_call_vid_strm_op_param;


然后调用这个函数去配置：

/** * Add, remove, modify, and/or manipulate video media stream for the * specified call. This may trigger a re-INVITE or UPDATE to be sent * for the call. * * @param call_id	Call identification. * @param op		The video stream operation to be performed, *			possible values are #pjsua_call_vid_strm_op. * @param param		The parameters for the video stream operation, *			or NULL for the default parameter values *			(see #pjsua_call_vid_strm_op_param). * * @return		PJ_SUCCESS on success or the appropriate error. */PJ_DECL(pj_status_t) pjsua_call_set_vid_strm (				pjsua_call_id call_id,				pjsua_call_vid_strm_op op,				const pjsua_call_vid_strm_op_param *param);


检索the call，获得video stream index：

/** * Get the media stream index of the default video stream in the call. * Typically this will just retrieve the stream index of the first * activated video stream in the call. * * @param call_id	Call identification. * * @return		The media stream index or -1 if no video stream * 			is present in the call. */PJ_DECL(int) pjsua_call_get_vid_stream_idx(pjsua_call_id call_id);


5.5 视频呼叫信息：


pjsua_call_info 中增加了一些新的片段用来描述更多的媒体信息。

/** Number of media streams in this call */    unsigned		media_cnt;    /** Array of media stream information */    struct    {	/** Media index in SDP. */	unsigned		index;	/** Media type. */	pjmedia_type		type;	/** Media direction. */	pjmedia_dir		dir;	/** Call media status. */	pjsua_call_media_status status;	/** The specific media stream info. */	union {	    /** Audio stream */	    struct {		/** The conference port number for the call.  */		pjsua_conf_port_id   conf_slot;	    } aud;	    /** Video stream */	    struct {		/**		 * The window id for incoming video, if any, or		 * PJSUA_INVALID_ID.		 */		pjsua_vid_win_id     win_in;		/** The video capture device for outgoing transmission,		 *  if any, or PJMEDIA_VID_INVALID_DEV		 */		pjmedia_vid_dev_index	cap_dev;	    } vid;	} stream;    } media[PJMEDIA_MAX_SDP_MEDIA];

还有以下几类API，不一一列举：


5.6 Video Call Stream Information and Statistic


5.7 Video Window API


5.8 Video Codec API
