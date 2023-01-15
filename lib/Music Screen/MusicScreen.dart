import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  Color bgColor = Colors.cyanAccent;

  //defining audio plugin
  final OnAudioQuery _audioQuery = OnAudioQuery();

  //Defining player
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<SongModel> songs = [];
  String currentSongTitle = '';
  int currentIndex = 0;

  bool isPlayerViewVisible = false;

  //define a method to set the player view visibility
  void _changePlayerViewVisibility() {
    setState(
      () {
        isPlayerViewVisible = !isPlayerViewVisible;
      },
    );
  }

  //duration state stream
  Stream<DurationState> get _durationStateStream =>
      Rx.combineLatest2<Duration, Duration?, DurationState>(
        _audioPlayer.positionStream,
        _audioPlayer.durationStream,
        (position, duration) =>
            DurationState(position: position, total: duration ?? Duration.zero),
      );

  //request permission from initStateMethod
  @override
  void initState() {
    super.initState();
    requestStoragePermission();

    // current playing songs index listener to be updated
    _audioPlayer.currentIndexStream.listen(
      (event) {
        if (event != null) {
          _updateCurrentPlayingSongDetails(event);
        }
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isPlayerViewVisible) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56.0, right: 20.0, left: 20.0),
            decoration: BoxDecoration(color: bgColor),
            child: Column(
              children: [
                //exit button and the song title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: _changePlayerViewVisibility,
                        child: Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: getDecoration(
                              BoxShape.circle, const Offset(2, 2), 2.0, 0.0),
                          child: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 5,
                      child: Text(
                        currentSongTitle,
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    )
                  ],
                ),
                Container(
                  width: 300,
                  height: 300,
                  margin: const EdgeInsets.only(top: 30, bottom: 30),
                  decoration: getDecoration(
                      BoxShape.circle, const Offset(2, 2), 2.0, 2.0),
                  child: QueryArtworkWidget(
                    id: songs[currentIndex].id,
                    type: ArtworkType.AUDIO,
                    artworkBorder: BorderRadius.circular(200.0),
                  ),
                ),

                //for slider,position and duration widgets
                Column(
                  children: [
                    //slider
                    Container(
                      padding: EdgeInsets.zero,
                      margin: const EdgeInsets.only(bottom: 4.0),
                      decoration: getRectDecoration(BorderRadius.circular(20.0),
                          const Offset(2, 2), 2.0, 0.0),

                      //slider bar duration state stream
                      child: StreamBuilder<DurationState>(
                        stream: _durationStateStream,
                        builder: (context, snapshot) {
                          final durationState = snapshot.data;
                          final progress =
                              durationState?.position ?? Duration.zero;
                          final total = durationState?.total ?? Duration.zero;

                          return ProgressBar(
                            progress: progress,
                            total: total,
                            barHeight: 20.0,
                            baseBarColor: bgColor,
                            progressBarColor: const Color(0xEE9E9E9E),
                            thumbColor: Colors.white60.withBlue(99),
                            timeLabelTextStyle: const TextStyle(
                              fontSize: 0,
                            ),
                            onSeek: (duration) {
                              _audioPlayer.seek(duration);
                            },
                          );
                        },
                      ),
                    ),

                    //position progress and total text
                    StreamBuilder<DurationState>(
                      stream: _durationStateStream,
                      builder: (context, snapshot) {
                        final durationState = snapshot.data;
                        final progress =
                            durationState?.position ?? Duration.zero;
                        final total = durationState?.total ?? Duration.zero;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              child: Text(
                                progress.toString().split(".")[0],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                total.toString().split(".")[0],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                // for previous, play/pause and next control buttons
                Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      //skip to previous
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            if (_audioPlayer.hasPrevious) {
                              _audioPlayer.seekToPrevious();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(2, 2), 2.0, 0.0),
                            child: const Icon(
                              Icons.skip_previous,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      //play/pause
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            if (_audioPlayer.playing) {
                              _audioPlayer.pause();
                            } else {
                              if (_audioPlayer.currentIndex != null) {
                                _audioPlayer.play();
                              }
                            }
                          },
                          child: Container(
                              padding: const EdgeInsets.all(20.0),
                              margin: const EdgeInsets.only(
                                  right: 20.0, left: 20.0),
                              decoration: getDecoration(BoxShape.circle,
                                  const Offset(2, 2), 2.0, 2.0),
                              child: StreamBuilder<bool>(
                                stream: _audioPlayer.playingStream,
                                builder: (context, snapshot) {
                                  bool? playingState = snapshot.data;
                                  //if playingState is not null and is playing
                                  if (playingState != null && playingState) {
                                    return const Icon(
                                      Icons.pause,
                                      size: 30,
                                      color: Colors.black,
                                    );
                                  }
                                  return const Icon(
                                    Icons.play_arrow,
                                    size: 30,
                                    color: Colors.black,
                                  );
                                },
                              )),
                        ),
                      ),

                      //for skip to next
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            if (_audioPlayer.hasNext) {
                              _audioPlayer.seekToNext();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(2, 2), 2.0, 2.0),
                            child: const Icon(
                              Icons.skip_next,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //for go to playlist, shuffle, repeat
                Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      //go to playlist button
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            _changePlayerViewVisibility();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            margin:  const EdgeInsets.only(right: 30.0, ),
                            decoration:  getDecoration(BoxShape.circle, const Offset(2, 2), 2.0, 0.0),
                            child: const Icon(Icons.list_alt, color: Colors.black,),
                          ),
                        ),
                      ),

                      //for shuffle of playlist
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            _audioPlayer.setShuffleModeEnabled(true);
                            toast(context, "Shuffling enabled");
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            margin:
                                const EdgeInsets.only(right: 30.0, ),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(2, 2), 2.0, 0.0),
                            child: const Icon(
                              Icons.shuffle,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      //for repeat mode
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            _audioPlayer.loopMode == LoopMode.one
                                ? _audioPlayer.setLoopMode(LoopMode.all)
                                : _audioPlayer.setLoopMode(LoopMode.one);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: getDecoration(
                                BoxShape.circle, const Offset(2, 2), 2.0, 2.0),
                            child:  StreamBuilder<LoopMode>(
                              stream: _audioPlayer.loopModeStream,
                              builder: (context, snapshot){
                                final loopMode = snapshot.data;
                                if(LoopMode.one == loopMode){
                                  return const Icon(Icons.repeat_one, color: Colors.black,);
                                }
                                return const Icon(Icons.repeat, color: Colors.black,);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text('Musique'),
      ),
      body: FutureBuilder<List<SongModel>>(
        future: _audioQuery.querySongs(
          sortType: null,
          orderType: OrderType.ASC_OR_SMALLER,
          uriType: UriType.EXTERNAL,
          ignoreCase: true,
        ),
        builder: (context, item) {
          //load the content indicator
          if (item.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (item.data!.isEmpty) {
            return const Center(
              child: Text('There is no any songs'),
            );
          }
          //if there is songs available then following process occurs

          songs.clear();
          songs = item.data!;
          return ListView.builder(
            itemCount: item.data!.length, //counting the number of songs
            itemBuilder: (context, index) {
              return Container(
                margin:
                    const EdgeInsets.only(top: 15.0, left: 12.0, right: 16.0),
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 4.0,
                        offset: Offset(-4, -4),
                        color: Colors.white70,
                      ),
                      BoxShadow(
                        blurRadius: 4.0,
                        offset: Offset(4, 4),
                        color: Colors.black,
                      ),
                    ]),
                child: ListTile(
                  textColor: Colors.black,
                  title: Text(item.data![index].title),
                  subtitle: Text(
                    item.data![index].displayName,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                  trailing: const Icon(Icons.more_vert),
                  leading: QueryArtworkWidget(
                    id: item.data![index].id,
                    type: ArtworkType.AUDIO,
                  ),
                  onTap: () async {
                    //show the player view
                    _changePlayerViewVisibility();

                    toast(context, "Playing:${item.data![index].title}");
                    //loading the audio from source and catch any errors.
                    // String? uri = item.data![index].uri;
                    // await _audioPlayer
                    //     .setAudioSource(AudioSource.uri(Uri.parse(uri!)));
                    await _audioPlayer.setAudioSource(
                        createPlaylist(item.data!),
                        initialIndex: index);
                    await _audioPlayer.play();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void toast(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
      ),
    );
  }

  void requestStoragePermission() async {
    if (!kIsWeb) {
      // kIsWeb means if it is not web
      bool permissionStatus = await _audioQuery.permissionsStatus();
      //waiting for permission
      if (!permissionStatus) {
        await _audioQuery.permissionsRequest();
        //requesting the permission
      }
      setState(() {});
    }
  }

  ConcatenatingAudioSource createPlaylist(List<SongModel> songs) {
    List<AudioSource> sources = [];
    for (var song in songs) {
      sources.add(
        AudioSource.uri(
          Uri.parse(song.uri!),
        ),
      );
    }
    return ConcatenatingAudioSource(children: sources);
  }

  //details update center
  void _updateCurrentPlayingSongDetails(int event) {
    setState(
      () {
        if (songs.isNotEmpty) {
          currentSongTitle = songs[event].title;
          currentIndex = event;
        }
      },
    );
  }

  getDecoration(
      BoxShape shape, Offset offset, double blurRadius, double spreadRadius) {
    return BoxDecoration(
      color: bgColor,
      shape: shape,
      boxShadow: [
        BoxShadow(
          offset: -offset,
          color: Colors.white24,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
        BoxShadow(
          offset: offset,
          color: Colors.black,
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ],
    );
  }

  BoxDecoration getRectDecoration(BorderRadius borderRadius, Offset offset,
      double blurRadius, double spreadRadius) {
    return BoxDecoration(
        borderRadius: borderRadius,
        color: bgColor,
        boxShadow: [
          BoxShadow(
            offset: -offset,
            color: Colors.white24,
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          ),
          BoxShadow(
            offset: offset,
            color: Colors.black,
            blurRadius: blurRadius,
            spreadRadius: spreadRadius,
          )
        ]);
  }
}

//duration class
class DurationState {
  DurationState({this.position = Duration.zero, this.total = Duration.zero});
  Duration position, total;
}
