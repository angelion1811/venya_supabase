import 'package:flutter/material.dart';
import 'package:ven_app/splashScreen/splash_screen.dart';

class PayFareAmountDialog extends StatefulWidget {

  double? fareAmount;

  PayFareAmountDialog({this.fareAmount});

  @override
  State<PayFareAmountDialog> createState() => _PayFareAmountDialogState();
}

class _PayFareAmountDialogState extends State<PayFareAmountDialog> {
  @override
  Widget build(BuildContext context) {

    bool darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        margin: EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: darkTheme? Colors.black : Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 20,),

            Text("Tarifa a Pagar".toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkTheme ? Colors.amber.shade400: Colors.white,
                    )
                  ,),
              SizedBox(height: 20,),
              Divider(
                thickness: 2,
                color: darkTheme ? Colors.amber.shade400: Colors.white,
              ),
              SizedBox(height: 10,),
              Text(
                  "\$ "+widget.fareAmount.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkTheme? Colors.amber.shade400:Colors.white,
                    fontSize: 50,
                  ),
              ),
              SizedBox(height: 10,),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  "Este es el monto total de la tarifa del viaje. Por favor pague al conductor.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: darkTheme? Colors.amber.shade400:Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20,),
              Padding(
                  padding: EdgeInsets.all(10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: darkTheme ? Colors.amber.shade400 : Colors.white
                    ),
                    onPressed: (){
                      Future.delayed(const Duration(milliseconds: 10000), (){
                          Navigator.pop(context, "Cash Paid");
                          //Navigator.push(context, MaterialPageRoute(builder: (c)=>SplashScreen()));
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            "Pagar en efectivo",
                          style: TextStyle(
                            fontSize: 20,
                            color: darkTheme ? Colors.black : Colors.blue,
                            fontWeight: FontWeight.bold,

                          )
                        ),
                        Text(
                          "\$"+widget.fareAmount.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: darkTheme? Colors.black:Colors.blue
                          ),
                        )
                      ],
                    ),
                  )
              )
          ],
        ),
      ),
    );
  }
}
