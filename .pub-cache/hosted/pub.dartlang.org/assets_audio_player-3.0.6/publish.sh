cd assets_audio_player_web
./publish.sh
cd ..

flutter format lib/
pub publish --force

git commit -am "published" && git push